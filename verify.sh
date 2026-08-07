#!/usr/bin/env bash
# =============================================================================
# verify.sh  —  prove every dataset actually landed, in the right schema
# =============================================================================
# Run from the host after `docker compose up -d` has settled:
#
#   ./verify.sh              # all engines
#   ./verify.sh postgres     # one engine
#                            # (postgres | mysql | sqlserver | oracle | sqlite)
#
# Row counts are exact COUNT(*) values, not planner estimates, so a table that
# was created but never populated shows as 0 instead of hiding behind missing
# statistics. Engines whose container is not running are skipped with a note
# rather than failing the run.
#
# Exit status: 0 if every engine checked reported data in the right place,
# 1 if any engine was reachable but came back empty, misplaced, or errored.
# =============================================================================
set -uo pipefail

cd "$(dirname "$0")"

# Load .env for passwords/ports if present, without clobbering real env vars
if [ -f .env ]; then
    set -a
    # shellcheck disable=SC1091
    . ./.env
    set +a
fi

PG_USER="${POSTGRES_USER:-postgres}"
MYSQL_PASS="${MYSQL_ROOT_PASSWORD:-mysql123}"
MSSQL_PASS="${MSSQL_PASSWORD:-SqlServer123!}"
ORA_PASS="${ORACLE_PASSWORD:-Oracle123!}"

FAILED=0
fail() { echo "     !! $*"; FAILED=1; }

heading() {
    echo
    echo "======================================================================"
    echo "  $1"
    echo "======================================================================"
}

running() {   # running <container> → 0 if up
    [ "$(docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null)" = "true" ]
}

is_num() { [[ "${1:-}" =~ ^[0-9]+$ ]]; }

# ─────────────────────────────────────────────────────────────────────────────
# PostgreSQL — 6 databases, one named schema each
# ─────────────────────────────────────────────────────────────────────────────
pg() { docker exec -i db_postgres psql -U "$PG_USER" -d "$1" -tAX -F'|' -c "$2" 2>&1; }

# Exact COUNT(*) for every base table in a schema, summed, without leaving SQL
pg_schema_stats() {
    pg "$1" "
        SELECT count(*),
               coalesce(sum((xpath('/row/c/text()',
                    query_to_xml(format('SELECT count(*) AS c FROM %I.%I',
                                        table_schema, table_name),
                                 false, true, '')))[1]::text::bigint), 0)
          FROM information_schema.tables
         WHERE table_schema = '$2' AND table_type = 'BASE TABLE';"
}

verify_postgres() {
    heading "PostgreSQL  (localhost:${POSTGRES_PORT:-5432})"
    if ! running db_postgres; then echo "  SKIPPED — db_postgres is not running."; return; fi

    printf '  %-11s %-11s %7s %11s   %s\n' DATABASE SCHEMA TABLES ROWS SEARCH_PATH
    printf '  %-11s %-11s %7s %11s   %s\n' ----------- ----------- ------- ----------- -----------

    for db in chinook pagila employees northwind ecommerce world; do
        out=$(pg_schema_stats "$db" "$db")
        tables=${out%%|*}
        rows=${out##*|}

        if ! is_num "$tables" || ! is_num "$rows"; then
            printf '  %-11s ERROR\n' "$db"
            fail "$db: $out"
            continue
        fi

        sp=$(pg "$db" "SHOW search_path;")
        printf '  %-11s %-11s %7s %11s   %s\n' "$db" "$db" "$tables" "$rows" "$sp"

        [ "$tables" -gt 0 ] || fail "$db.$db has no tables"
        [ "$rows"   -gt 0 ] || fail "$db.$db has no rows"

        # Anything left in public means a loader missed its search_path
        stray=$(pg "$db" "SELECT count(*) FROM information_schema.tables
                           WHERE table_schema='public' AND table_type='BASE TABLE';")
        is_num "$stray" && [ "$stray" -gt 0 ] && \
            fail "$db: $stray table(s) still in public — expected 0"
    done

    # The default `postgres` database should hold nothing. It used to collect
    # world's tables, because the Postgres entrypoint also executes any *.sql
    # left in /docker-entrypoint-initdb.d — hence postgres/assets/.
    stray=$(pg postgres "SELECT count(*) FROM information_schema.tables
                          WHERE table_schema='public' AND table_type='BASE TABLE';")
    is_num "$stray" && [ "$stray" -gt 0 ] && \
        fail "default 'postgres' database has $stray stray table(s) — expected 0"
}

# ─────────────────────────────────────────────────────────────────────────────
# MySQL — 5 databases (a database *is* the schema)
# ─────────────────────────────────────────────────────────────────────────────
# MYSQL_PWD keeps the password off the command line and out of the client's
# "insecure" warning, which would otherwise pollute every captured value.
my_q() {
    docker exec -i -e MYSQL_PWD="$MYSQL_PASS" db_mysql \
        mysql -uroot --batch --skip-column-names -e "$1" 2>&1
}

verify_mysql() {
    heading "MySQL  (localhost:${MYSQL_PORT:-3306})"
    if ! running db_mysql; then echo "  SKIPPED — db_mysql is not running."; return; fi

    printf '  %-11s %7s %11s\n' DATABASE TABLES ROWS
    printf '  %-11s %7s %11s\n' ----------- ------- -----------

    for db in chinook sakila northwind world menagerie; do
        # information_schema.TABLE_ROWS is an estimate for InnoDB, so build a
        # UNION ALL of exact COUNT(*)s from the table list and run that instead.
        q=$(my_q "
            SELECT GROUP_CONCAT(CONCAT('SELECT COUNT(*) AS c FROM \`', TABLE_NAME, '\`')
                                SEPARATOR ' UNION ALL ')
              FROM information_schema.TABLES
             WHERE TABLE_SCHEMA = '$db' AND TABLE_TYPE = 'BASE TABLE';")

        if [ -z "$q" ] || [ "$q" = "NULL" ]; then
            printf '  %-11s %7s %11s\n' "$db" 0 0
            fail "$db has no tables (database missing or seeding failed): $q"
            continue
        fi

        tables=$(my_q "
            SELECT COUNT(*) FROM information_schema.TABLES
             WHERE TABLE_SCHEMA = '$db' AND TABLE_TYPE = 'BASE TABLE';")
        rows=$(my_q "USE \`$db\`; SELECT SUM(c) FROM ( $q ) t;")

        if ! is_num "$tables" || ! is_num "$rows"; then
            printf '  %-11s ERROR\n' "$db"
            fail "$db: $(printf '%s' "$tables $rows" | tr '\n' ' ')"
            continue
        fi

        printf '  %-11s %7s %11s\n' "$db" "$tables" "$rows"
        [ "$tables" -gt 0 ] || fail "$db has no tables"
        [ "$rows"   -gt 0 ] || fail "$db has no rows"
    done

    # Upstream's Chinook script creates `Chinook`; 01_chinook.sh lower-cases it.
    # Both existing would mean the rewrite half-applied.
    stray=$(my_q "SELECT COUNT(*) FROM information_schema.SCHEMATA
                   WHERE SCHEMA_NAME = 'Chinook' COLLATE utf8mb4_bin;")
    is_num "$stray" && [ "$stray" -gt 0 ] && \
        fail "a capital-C 'Chinook' database exists — expected only lower-case 'chinook'"
}

# ─────────────────────────────────────────────────────────────────────────────
# SQL Server — 2 databases, one named schema each
# ─────────────────────────────────────────────────────────────────────────────
mssql() {
    docker exec -i db_sqlserver /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U sa -P "$MSSQL_PASS" -No -h -1 -W -s'|' "$@" 2>&1
}

verify_sqlserver() {
    heading "SQL Server  (localhost:${MSSQL_PORT:-1433})"
    if ! running db_sqlserver; then echo "  SKIPPED — db_sqlserver is not running."; return; fi

    printf '  %-11s %-11s %7s %11s\n' DATABASE SCHEMA TABLES ROWS
    printf '  %-11s %-11s %7s %11s\n' ----------- ----------- ------- -----------

    # database → the schema its objects are supposed to be in
    for pair in "Chinook:chinook" "Northwind:northwind"; do
        db=${pair%%:*}
        want=${pair##*:}

        out=$(mssql -d "$db" -Q "
            SET NOCOUNT ON;
            SELECT s.name + '|' + CAST(COUNT(DISTINCT t.object_id) AS varchar(20))
                   + '|' + CAST(ISNULL(SUM(CASE WHEN p.index_id IN (0,1)
                                                THEN p.rows ELSE 0 END), 0) AS varchar(20))
              FROM sys.tables t
              JOIN sys.schemas s ON s.schema_id = t.schema_id
              LEFT JOIN sys.partitions p ON p.object_id = t.object_id
             GROUP BY s.name ORDER BY s.name;")

        found_want=0
        # Read into an array first: a `while read` on the right of a pipe runs in
        # a subshell and would lose FAILED / found_want.
        mapfile -t lines < <(printf '%s\n' "$out" | grep -E '^[A-Za-z][A-Za-z0-9_]*\|[0-9]+\|[0-9]+$')
        if [ "${#lines[@]}" -eq 0 ]; then
            printf '  %-11s ERROR\n' "$db"
            fail "$db: $(printf '%s' "$out" | tr '\n' ' ')"
            continue
        fi

        for line in "${lines[@]}"; do
            IFS='|' read -r schema tables rows <<<"$line"
            printf '  %-11s %-11s %7s %11s\n' "$db" "$schema" "$tables" "$rows"
            if [ "$schema" = "$want" ]; then
                found_want=1
                [ "$rows" -gt 0 ] || fail "$db.$want has no rows"
            elif [ "$schema" = "dbo" ]; then
                fail "$db: $tables table(s) still in dbo — expected schema $want"
            fi
        done
        [ "$found_want" -eq 1 ] || fail "$db: schema $want not found"
    done

    # The throwaway seeding login should not have survived
    left=$(mssql -Q "SET NOCOUNT ON;
        SELECT COUNT(*) FROM sys.server_principals WHERE name = 'nw_seeder';" | tr -cd '0-9')
    [ "${left:-0}" = "0" ] || echo "  NOTE: seeding login nw_seeder still exists (harmless, dev only)."
}

# ─────────────────────────────────────────────────────────────────────────────
# Oracle XE — 4 schemas inside XEPDB1
# ─────────────────────────────────────────────────────────────────────────────
verify_oracle() {
    heading "Oracle XE  (localhost:${ORACLE_PORT:-1521}/XEPDB1)"
    if ! running db_oracle; then echo "  SKIPPED — db_oracle is not running."; return; fi

    # No shell inside the container, so the '!' in the password needs no escaping
    out=$(docker exec -i db_oracle \
            sqlplus -s "system/${ORA_PASS}@//localhost/XEPDB1" <<'SQL' 2>&1
SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK OFF
SET HEADING OFF
SET PAGESIZE 0
DECLARE
    v_rows   NUMBER;
    v_total  NUMBER;
    v_tables NUMBER;
BEGIN
    FOR s IN (SELECT username FROM dba_users
               WHERE username IN ('CHINOOK','HR','CO','SH') ORDER BY username) LOOP
        v_total  := 0;
        v_tables := 0;
        FOR t IN (SELECT table_name FROM dba_tables
                   WHERE owner = s.username
                     AND nested = 'NO'
                     AND (iot_type IS NULL OR iot_type = 'IOT')) LOOP
            EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM "' || s.username || '"."' ||
                              t.table_name || '"' INTO v_rows;
            v_total  := v_total + v_rows;
            v_tables := v_tables + 1;
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('RESULT|' || s.username || '|' || v_tables || '|' || v_total);
    END LOOP;
END;
/
EXIT;
SQL
)

    printf '  %-11s %-11s %7s %11s\n' 'PDB' SCHEMA TABLES ROWS
    printf '  %-11s %-11s %7s %11s\n' ----------- ----------- ------- -----------

    mapfile -t lines < <(printf '%s\n' "$out" | grep '^RESULT|')
    if [ "${#lines[@]}" -eq 0 ]; then
        printf '  ERROR — no schemas reported\n'
        fail "oracle: $(printf '%s' "$out" | grep -E 'ORA-|SP2-' | head -3 | tr '\n' ' ')"
        return
    fi

    seen=""
    for line in "${lines[@]}"; do
        IFS='|' read -r _ schema tables rows <<<"$line"
        printf '  %-11s %-11s %7s %11s\n' XEPDB1 "$schema" "$tables" "$rows"
        seen="$seen $schema"
        [ "$rows" -gt 0 ] || fail "schema $schema has no rows"
    done

    for want in CHINOOK HR CO SH; do
        case " $seen " in
            *" $want "*) ;;
            *)
                if [ "$want" = "SH" ] && [ "${ORACLE_SKIP_SH:-false}" = "true" ]; then
                    echo "  SH absent — expected, ORACLE_SKIP_SH=true"
                else
                    fail "schema $want missing"
                fi
                ;;
        esac
    done
}

# ─────────────────────────────────────────────────────────────────────────────
# SQLite — one .db file per dataset, served by Datasette
# ─────────────────────────────────────────────────────────────────────────────
verify_sqlite() {
    heading "SQLite / Datasette  (http://localhost:${SQLITE_PORT:-8001})"
    if ! running db_sqlite; then echo "  SKIPPED — db_sqlite is not running."; return; fi

    printf '  %-14s %7s %11s\n' FILE TABLES ROWS
    printf '  %-14s %7s %11s\n' -------------- ------- -----------

    for db in chinook menagerie northwind; do
        # sqlite3 has no "count all rows" builtin; build one UNION ALL query
        # from sqlite_master and run it. Quoting handles table names with
        # spaces (Northwind has none today, but Chinook-style dumps can).
        out=$(docker exec -i db_sqlite sh -s "$db" <<'INNER' 2>&1
db="$1"
f="/data/${db}.db"
[ -f "$f" ] || { echo "MISSING"; exit 0; }
tables=$(sqlite3 "$f" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';")
q=$(sqlite3 "$f" "SELECT group_concat('SELECT COUNT(*) AS c FROM \"' || replace(name,'\"','\"\"') || '\"', ' UNION ALL ') FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';")
if [ -n "$q" ] && [ "$q" != "" ]; then
    rows=$(sqlite3 "$f" "SELECT SUM(c) FROM ( $q );")
else
    rows=0
fi
echo "${tables}|${rows}"
INNER
)
        if [ "$out" = "MISSING" ]; then
            printf '  %-14s %7s %11s\n' "${db}.db" - -
            fail "${db}.db not found in the sqlite_data volume"
            continue
        fi
        tables=${out%%|*}
        rows=${out##*|}
        if ! is_num "$tables" || ! is_num "$rows"; then
            printf '  %-14s ERROR\n' "${db}.db"
            fail "${db}.db: $(printf '%s' "$out" | tr '\n' ' ')"
            continue
        fi
        printf '  %-14s %7s %11s\n' "${db}.db" "$tables" "$rows"
        [ "$tables" -gt 0 ] || fail "${db}.db has no tables"
        [ "$rows"   -gt 0 ] || fail "${db}.db has no rows"
    done
}

# ─────────────────────────────────────────────────────────────────────────────
case "${1:-all}" in
    all)       verify_postgres; verify_mysql; verify_sqlserver; verify_oracle; verify_sqlite ;;
    postgres)  verify_postgres ;;
    mysql)     verify_mysql ;;
    sqlserver) verify_sqlserver ;;
    oracle)    verify_oracle ;;
    sqlite)    verify_sqlite ;;
    *) echo "usage: $0 [all|postgres|mysql|sqlserver|oracle|sqlite]" >&2; exit 2 ;;
esac

echo
if [ "$FAILED" -eq 0 ]; then
    echo "verify: OK — every dataset present, in its own schema"
else
    echo "verify: PROBLEMS FOUND (see !! lines above)"
fi
exit "$FAILED"
