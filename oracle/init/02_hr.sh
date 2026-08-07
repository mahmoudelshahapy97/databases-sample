#!/usr/bin/env bash
# =============================================================================
# 02_hr.sh  —  Load HR (Human Resources) schema into Oracle XE
# Source: oracle/data/human_resources/hr_create.sql   (DDL)
#                                     hr_populate.sql (data)
#
# The official Oracle HR scripts are designed for SQL*Plus and contain:
#   - SQL*Plus commands: rem, SET, Prompt — must be stripped
#   - ALTER SESSION SET NLS_LANGUAGE=American — kept (valid Oracle SQL)
#   - PL/SQL BEGIN...END;/ blocks in hr_populate.sql — valid, kept
#   - ORGANIZATION INDEX clause in hr_create.sql — valid Oracle DDL, kept
#   - Circular FK: DEPARTMENTS.manager_id → EMPLOYEES and vice-versa
#     Oracle handles this via ALTER TABLE ADD CONSTRAINT after data load.
#
# This script:
#   1. Creates the HR user as SYSTEM
#   2. Strips SQL*Plus-only directives and runs hr_create.sql as HR
#   3. Strips SQL*Plus-only directives and runs hr_populate.sql as HR
# =============================================================================
set -euo pipefail

PASS="${ORACLE_PASSWORD}"
HR_BASE="/source/human_resources"

echo "======================================================"
echo "  Oracle: Setting up HR schema"
echo "======================================================"

# ── Step 1: Create HR user as SYSTEM ──────────────────────────────────────────
sqlplus -s "system/${PASS}@//localhost/XEPDB1" <<-EOF
    WHENEVER SQLERROR EXIT SQL.SQLCODE
    WHENEVER OSERROR EXIT FAILURE

    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM dba_users WHERE username = 'HR';
        IF v_count > 0 THEN
            EXECUTE IMMEDIATE 'DROP USER hr CASCADE';
        END IF;
    END;
    /

    CREATE USER hr IDENTIFIED BY "${PASS}"
        DEFAULT TABLESPACE USERS
        TEMPORARY TABLESPACE TEMP
        QUOTA UNLIMITED ON USERS;

    GRANT CONNECT, RESOURCE, CREATE VIEW, CREATE SEQUENCE,
          CREATE PROCEDURE, CREATE TRIGGER TO hr;

    EXIT;
EOF

echo "  HR user created."

# ── Helper: strip SQL*Plus-only lines ─────────────────────────────────────────
strip_sqlplus() {
    local infile="$1"
    grep -viE '^(rem( |$)|set |prompt|@)' "$infile"
}

# ── Step 2: Load HR DDL (tables, sequences, indexes, constraints) ──────────────
echo "  Loading HR DDL (hr_create.sql)..."
TMPFILE=$(mktemp /tmp/hr_create_XXXXXX.sql)
strip_sqlplus "${HR_BASE}/hr_create.sql" > "$TMPFILE"
sqlplus -s "hr/${PASS}@//localhost/XEPDB1" <<-EOF
    WHENEVER SQLERROR EXIT SQL.SQLCODE
    WHENEVER OSERROR EXIT FAILURE
    @${TMPFILE}
    EXIT;
EOF
rm -f "$TMPFILE"
echo "  HR schema created."

# ── Step 3: Load HR data (PL/SQL BEGIN...END;/ blocks) ────────────────────────
echo "  Loading HR data (hr_populate.sql, ~220 rows)..."
TMPFILE=$(mktemp /tmp/hr_populate_XXXXXX.sql)
strip_sqlplus "${HR_BASE}/hr_populate.sql" > "$TMPFILE"
sqlplus -s "hr/${PASS}@//localhost/XEPDB1" <<-EOF
    WHENEVER SQLERROR EXIT SQL.SQLCODE
    WHENEVER OSERROR EXIT FAILURE
    @${TMPFILE}
    EXIT;
EOF
rm -f "$TMPFILE"
echo "  HR data loaded."

echo "HR Oracle loaded  ✓  (regions: 5, countries: 25, locations: 23,"
echo "                       departments: 27, jobs: 19, employees: 107,"
echo "                       job_history: ~10)"
