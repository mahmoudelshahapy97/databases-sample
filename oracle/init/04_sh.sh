#!/usr/bin/env bash
# =============================================================================
# 04_sh.sh  —  Load SH (Sales History) schema into Oracle XE
# Source: oracle/data/sales_history/sh_create.sql   (DDL)
#                                   sh_populate.sql (small tables)
#                                   *.csv           (large tables)
#
# SH is the heaviest dataset in this compose file: ~1.06 M rows across
# partitioned + bitmap-indexed tables, two materialized views, five dimensions,
# and a full stats gather. Budget 10–20 minutes of Oracle first-start time for
# it. Set ORACLE_SKIP_SH=true in .env to leave it out.
#
# ── Two upstream dependencies this script works around ───────────────────────
# 1. SQLcl. sh_populate.sql loads its six big tables with `LOAD <table>
#    <file>.csv`, a SQLcl command; the gvenzl image only ships SQL*Plus. The
#    six LOAD lines are rewritten into one @-call to /opt/seed/sh_load_csv.sql,
#    which does the same work with external tables. See that file for details.
# 2. Oracle Text. sh_populate.sql builds a CONTEXT index on
#    supplementary_demographics(comments), which needs CTXSYS — stripped out of
#    the -slim image variants. That statement is removed from the script and
#    retried afterwards only if CTXSYS is actually present.
#
# A failure here is reported loudly but does not abort container init, so the
# CHINOOK / HR / CO schemas stay usable if SH is the thing that breaks.
# =============================================================================
set -uo pipefail

PASS="${ORACLE_PASSWORD}"
SH_BASE="/source/sales_history"
LOADER="/opt/seed/sh_load_csv.sql"

if [ "${ORACLE_SKIP_SH:-false}" = "true" ]; then
    echo "======================================================"
    echo "  Oracle: SKIPPING SH schema (ORACLE_SKIP_SH=true)"
    echo "======================================================"
    exit 0
fi

echo "======================================================"
echo "  Oracle: Setting up SH (Sales History) schema"
echo "  ~1.06 M rows — this is the slow one, 10–20 min"
echo "======================================================"

seed_sh() {
    # ── Step 1: SH user, privileges, and the CSV directory object ─────────────
    sqlplus -s "system/${PASS}@//localhost/XEPDB1" <<-EOF || return 1
        WHENEVER SQLERROR EXIT SQL.SQLCODE
        WHENEVER OSERROR EXIT FAILURE
        SET SERVEROUTPUT ON

        DECLARE
            v_count NUMBER;
        BEGIN
            SELECT COUNT(*) INTO v_count FROM dba_users WHERE username = 'SH';
            IF v_count > 0 THEN
                EXECUTE IMMEDIATE 'DROP USER sh CASCADE';
            END IF;
        END;
        /

        CREATE USER sh IDENTIFIED BY "${PASS}"
            DEFAULT TABLESPACE USERS
            TEMPORARY TABLESPACE TEMP
            QUOTA UNLIMITED ON USERS;

        -- Same privilege set sh_install.sql grants, plus ALTER SESSION
        GRANT CREATE SESSION,
              ALTER SESSION,
              CREATE TABLE,
              CREATE VIEW,
              CREATE SEQUENCE,
              CREATE SYNONYM,
              CREATE TRIGGER,
              CREATE TYPE,
              CREATE PROCEDURE,
              CREATE MATERIALIZED VIEW,
              CREATE DIMENSION
          TO sh;

        -- The two materialized views are declared ENABLE QUERY REWRITE.
        -- Deprecated as a system privilege and implicit for own-schema views on
        -- modern releases, so a missing grant here is not fatal.
        BEGIN
            EXECUTE IMMEDIATE 'GRANT QUERY REWRITE TO sh';
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Note: QUERY REWRITE not grantable here - continuing.');
        END;
        /

        -- Oracle Text role, only if this image still has Oracle Text
        DECLARE
            v_count NUMBER;
        BEGIN
            SELECT COUNT(*) INTO v_count FROM dba_roles WHERE role = 'CTXAPP';
            IF v_count > 0 THEN
                EXECUTE IMMEDIATE 'GRANT CTXAPP TO sh';
            END IF;
        END;
        /

        -- External-table source for the six CSV files (read-only bind mount)
        CREATE OR REPLACE DIRECTORY sh_csv_dir AS '${SH_BASE}';
        GRANT READ ON DIRECTORY sh_csv_dir TO sh;

        EXIT;
EOF
    echo "  SH user created; SH_CSV_DIR → ${SH_BASE}"

    # ── Step 2: DDL — tables, partitions, constraints, MVs, views ────────────
    echo "  Loading SH DDL (sh_create.sql)..."
    sqlplus -s "sh/${PASS}@//localhost/XEPDB1" <<-EOF || return 1
        WHENEVER SQLERROR EXIT SQL.SQLCODE
        WHENEVER OSERROR EXIT FAILURE
        ALTER SESSION SET NLS_LANGUAGE=American;
        ALTER SESSION SET NLS_TERRITORY=America;
        @${SH_BASE}/sh_create.sql
        EXIT;
EOF
    echo "  SH schema created."

    # ── Step 3: Data ─────────────────────────────────────────────────────────
    # Rewrite the SQLcl-only bits. The first LOAD line becomes the @-call to the
    # external-table loader, which handles all six tables at once; the other
    # five LOAD lines and the `SET LOAD …` parameter line are dropped. Both
    # happen at the same point in the script — constraints disabled, bitmap
    # indexes not yet built — so the load order is unchanged in effect.
    local populate="/tmp/sh_populate_patched.sql"
    sed \
        -e "s#^LOAD costs costs\.csv#@${LOADER}#" \
        -e '/^LOAD /d' \
        -e '/^SET LOAD /d' \
        -e "/^CREATE INDEX sup_text_idx/,/PARAMETERS('nopopulate');/d" \
        "${SH_BASE}/sh_populate.sql" > "$populate" || return 1

    # Fail fast if the upstream script ever changes shape under us
    if ! grep -q "^@${LOADER}$" "$populate"; then
        echo "  ERROR: could not splice the CSV loader into sh_populate.sql."
        echo "         Upstream's 'LOAD costs costs.csv' line was not found."
        return 1
    fi

    echo "  Loading SH data (small tables inline + 6 CSVs via external tables)..."
    echo "  Then: bitmap indexes, materialized views, dimensions, stats gather."
    sqlplus -s "sh/${PASS}@//localhost/XEPDB1" <<-EOF || return 1
        WHENEVER SQLERROR EXIT SQL.SQLCODE
        WHENEVER OSERROR EXIT FAILURE
        @${populate}
        EXIT;
EOF
    rm -f "$populate"
    echo "  SH data loaded."

    # ── Step 4: Oracle Text index, if this image has Oracle Text ─────────────
    sqlplus -s "sh/${PASS}@//localhost/XEPDB1" <<-'EOF'
        SET SERVEROUTPUT ON
        SET FEEDBACK OFF
        DECLARE
            v_count NUMBER;
        BEGIN
            SELECT COUNT(*) INTO v_count FROM all_users WHERE username = 'CTXSYS';
            IF v_count = 0 THEN
                DBMS_OUTPUT.PUT_LINE('  Oracle Text (CTXSYS) absent from this image - skipping sup_text_idx.');
                RETURN;
            END IF;
            EXECUTE IMMEDIATE q'[CREATE INDEX sup_text_idx ON supplementary_demographics(comments)
                                 INDEXTYPE IS ctxsys.context PARAMETERS('nopopulate')]';
            DBMS_OUTPUT.PUT_LINE('  sup_text_idx (Oracle Text) created.');
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('  sup_text_idx skipped: ' || SQLERRM);
        END;
        /
        EXIT;
EOF

    # ── Step 5: Verify against upstream's expected counts ────────────────────
    sqlplus -s "sh/${PASS}@//localhost/XEPDB1" <<-'EOF'
        SET HEADING ON
        SET FEEDBACK OFF
        SET PAGESIZE 50
        COLUMN "Table" FORMAT A28
        SELECT 'channels' AS "Table", 5 AS "expected", COUNT(1) AS "actual" FROM channels
        UNION ALL SELECT 'countries',                      35, COUNT(1) FROM countries
        UNION ALL SELECT 'products',                       72, COUNT(1) FROM products
        UNION ALL SELECT 'promotions',                    503, COUNT(1) FROM promotions
        UNION ALL SELECT 'times',                        1826, COUNT(1) FROM times
        UNION ALL SELECT 'supplementary_demographics',   4500, COUNT(1) FROM supplementary_demographics
        UNION ALL SELECT 'customers',                   55500, COUNT(1) FROM customers
        UNION ALL SELECT 'costs',                       82112, COUNT(1) FROM costs
        UNION ALL SELECT 'sales',                      918843, COUNT(1) FROM sales;
        EXIT;
EOF

    return 0
}

START=$(date +%s)
if seed_sh; then
    echo "SH Oracle loaded  ✓  ($(( ($(date +%s) - START) / 60 )) min)"
    echo "                      (channels, countries, customers, products,"
    echo "                       promotions, times, costs, sales,"
    echo "                       supplementary_demographics + 2 MVs, 5 dimensions)"
else
    echo "!!===================================================================!!"
    echo "!! WARNING: SH (Sales History) seeding FAILED after $(( ($(date +%s) - START) / 60 )) min."
    echo "!!"
    echo "!! The SH schema may be partially populated. CHINOOK, HR and CO are"
    echo "!! unaffected and remain usable."
    echo "!!"
    echo "!! Most likely causes, in order:"
    echo "!!   * Container out of memory — SH needs headroom above the other"
    echo "!!     schemas. Check:  docker inspect db_oracle --format '{{.State.OOMKilled}}'"
    echo "!!     and raise the oracle mem_limit in docker-compose.yml."
    echo "!!   * USERS tablespace out of space (SH adds roughly 200 MB)."
    echo "!!   * A feature missing from the -slim image variant."
    echo "!!"
    echo "!! To retry:      docker compose down && docker volume rm multidb_oracle_data"
    echo "!!                docker compose up -d oracle"
    echo "!! To skip it:    set ORACLE_SKIP_SH=true in .env"
    echo "!!===================================================================!!"
fi

# Never block the rest of container init on SH.
exit 0
