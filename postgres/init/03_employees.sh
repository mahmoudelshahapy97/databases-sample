#!/usr/bin/env bash
# =============================================================================
# 03_employees.sh  —  Load Employees (HR) schema *and data* into PostgreSQL
# Source: postgres/data/employees/employees.sql  (DDL — PG port)
#         postgres/data/employees/objects.sql     (views + stored functions)
#         postgres/data/employees/load_*.dump     (data — MySQL INSERT syntax)
# Target: database employees, schema employees
#
# The upstream PostgreSQL port ships DDL only, but the *data* in the repo root
# is portable: the load_*.dump files are plain multi-row
# `INSERT INTO `table` VALUES (…),(…);` statements. Stripping the MySQL
# backtick quoting is the only conversion needed — which is exactly what
# upstream's own postgresql/load_employees_db.sh does.
#
# Volume: ~4 M rows / ~170 MB of INSERT text, so this is the slowest part of a
# first `docker compose up`. Two session settings keep it to a few minutes:
#   * synchronous_commit = off      — no fsync per commit (data is reproducible)
#   * session_replication_role = replica
#         Skips FK trigger validation during the bulk load. Standard bulk-load
#         practice; the dumps are a consistent snapshot and the tables are
#         loaded parents-first anyway, so nothing is left dangling.
# =============================================================================
set -euo pipefail

DDL="/source/employees/employees.sql"
OBJ="/source/employees/objects.sql"
DUMPS="/source/employees"

echo "------------------------------------------------------"
echo "  Loading: employees.employees  (HR, 6 tables, ~4 M rows)"
echo "------------------------------------------------------"

# ── Schema structure ─────────────────────────────────────────────────────────
# Strip CREATE/DROP DATABASE and \connect — already on the target DB
echo "  → Structure (employees.sql)..."
{
    echo "SET search_path TO employees;"
    sed \
        -e '/^DROP DATABASE/d' \
        -e '/^CREATE DATABASE/d' \
        -e '/^\\\\connect/d' \
        -e '/^\\\\c /d' \
        "$DDL"
} | psql \
    -q -v ON_ERROR_STOP=1 \
    --username "$POSTGRES_USER" \
    --dbname   "employees"

# ── Views and helper functions ───────────────────────────────────────────────
if [ -f "$OBJ" ]; then
    echo "  → Views and functions (objects.sql)..."
    # Drop its \connect employees — a reconnect would discard the SET below
    {
        echo "SET search_path TO employees;"
        sed -e '/^\\\\connect/d' "$OBJ"
    } | psql \
        -q -v ON_ERROR_STOP=1 \
        --username "$POSTGRES_USER" \
        --dbname   "employees"
fi

# ── Data ─────────────────────────────────────────────────────────────────────
# load <label> <dump file>
load() {
    local label="$1" file="$2"
    printf '  → %-26s' "${label}..."
    {
        echo "SET search_path TO employees;"
        echo "SET synchronous_commit TO off;"
        echo "SET session_replication_role TO replica;"
        sed 's/`//g' "$file"
    } | psql \
        -q -v ON_ERROR_STOP=1 \
        --username "$POSTGRES_USER" \
        --dbname   "employees"
    echo "ok"
}

echo "  → Data (~170 MB of INSERT statements — this takes a few minutes)"
# Parents before children, so the data is FK-consistent independent of the
# replica-role setting above.
load "departments (9)"        "${DUMPS}/load_departments.dump"
load "employees (300 024)"    "${DUMPS}/load_employees.dump"
load "dept_emp (331 603)"     "${DUMPS}/load_dept_emp.dump"
load "dept_manager (24)"      "${DUMPS}/load_dept_manager.dump"
load "titles (443 308)"       "${DUMPS}/load_titles.dump"
load "salaries 1/3"           "${DUMPS}/load_salaries1.dump"
load "salaries 2/3"           "${DUMPS}/load_salaries2.dump"
load "salaries 3/3"           "${DUMPS}/load_salaries3.dump"

# ── Planner statistics + row-count report ────────────────────────────────────
echo "  → ANALYZE..."
psql -q -v ON_ERROR_STOP=1 \
     --username "$POSTGRES_USER" \
     --dbname   "employees" \
     -c "ANALYZE;"

psql -v ON_ERROR_STOP=1 \
     --username "$POSTGRES_USER" \
     --dbname   "employees" <<-'EOSQL'
    SELECT 'departments'  AS table_name, count(*) FROM departments
    UNION ALL SELECT 'employees',    count(*) FROM employees
    UNION ALL SELECT 'dept_emp',     count(*) FROM dept_emp
    UNION ALL SELECT 'dept_manager', count(*) FROM dept_manager
    UNION ALL SELECT 'titles',       count(*) FROM titles
    UNION ALL SELECT 'salaries',     count(*) FROM salaries;
EOSQL

echo "employees loaded  ✓  (schema *and* data — no longer DDL-only)"
