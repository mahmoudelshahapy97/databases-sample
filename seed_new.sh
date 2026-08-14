#!/usr/bin/env bash
# =============================================================================
# seed_new.sh  —  Manually seed booking + healthcare into running containers
# Run from WSL: bash seed_new.sh
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")"

# Load passwords from .env if present
if [ -f .env ]; then
    set -a; . ./.env; set +a
fi

PG_USER="${POSTGRES_USER:-postgres}"
MYSQL_PASS="${MYSQL_ROOT_PASSWORD:-mysql123}"
ORA_PASS="${ORACLE_PASSWORD:-Oracle123!}"
MSSQL_PASS="${MSSQL_PASSWORD:-SqlServer123!}"

ok()   { echo "  ✓  $*"; }
err()  { echo "  ✗  $*" >&2; }
head() { echo; echo "══════════════════════════════════════════"; echo "  $*"; echo "══════════════════════════════════════════"; }

# ─── PostgreSQL ───────────────────────────────────────────────────────────────
head "PostgreSQL — seeding booking + healthcare"

for db in booking healthcare; do
    echo "  → Creating database '${db}'..."
    docker exec db_postgres psql -U "$PG_USER" -d postgres -c \
        "CREATE DATABASE ${db};" 2>/dev/null || echo "  (database '${db}' already exists — skipping CREATE)"

    docker exec db_postgres psql -U "$PG_USER" -d "$db" -c \
        "CREATE SCHEMA IF NOT EXISTS ${db} AUTHORIZATION ${PG_USER};
         ALTER DATABASE ${db} SET search_path TO ${db}, public;" 2>&1

    echo "  → Loading ${db} data..."
    docker exec db_postgres sh -c \
        "{ echo 'SET search_path TO ${db};'; cat /source/${db}/${db}_pg.sql; } | \
         psql -U ${PG_USER} -d ${db} -v ON_ERROR_STOP=1" 2>&1 \
        && ok "${db} loaded into PostgreSQL" \
        || err "${db} load FAILED"
done

# ─── MySQL ────────────────────────────────────────────────────────────────────
head "MySQL — seeding booking + healthcare"

for db in booking healthcare; do
    echo "  → Loading ${db} data..."
    docker exec db_mysql sh -c \
        "MYSQL_PWD='${MYSQL_PASS}' mysql -uroot < /source/${db}/${db}.sql" 2>&1 \
        && ok "${db} loaded into MySQL" \
        || err "${db} load FAILED"
done

# ─── SQL Server ───────────────────────────────────────────────────────────────
head "SQL Server — seeding booking + healthcare"

echo "  → Loading booking data into SQL Server..."
docker exec db_sqlserver /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P "$MSSQL_PASS" -No -i /source/booking/booking_mssql.sql 2>&1 \
    && ok "booking loaded into SQL Server" \
    || err "booking load FAILED"

echo "  → Loading healthcare data into SQL Server..."
docker exec db_sqlserver /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P "$MSSQL_PASS" -No -i /source/healthcare/healthcare_mssql.sql 2>&1 \
    && ok "healthcare loaded into SQL Server" \
    || err "healthcare load FAILED"

# ─── Oracle ───────────────────────────────────────────────────────────────────
head "Oracle XE — seeding booking + healthcare"

for script in 05_booking.sh 06_healthcare.sh; do
    echo "  → Running /opt/seed/init/${script}..."
    docker exec -e ORACLE_PASSWORD="${ORA_PASS}" db_oracle \
        bash /opt/seed/init/${script} 2>&1 \
        && ok "${script} complete" \
        || err "${script} FAILED"
done

# ─── SQLite ───────────────────────────────────────────────────────────────────
head "SQLite — seeding booking + healthcare"

echo "  → Loading booking data into SQLite..."
docker exec db_sqlite /usr/bin/sqlite3 /data/booking.db ".read /source/booking/booking_sqlite.sql" 2>&1 \
    && ok "booking loaded into SQLite" \
    || err "booking load FAILED"

echo "  → Loading healthcare data into SQLite..."
docker exec db_sqlite /usr/bin/sqlite3 /data/healthcare.db ".read /source/healthcare/healthcare_sqlite.sql" 2>&1 \
    && ok "healthcare loaded into SQLite" \
    || err "healthcare load FAILED"

echo
echo "Done. Run ./verify.sh to confirm all engines."
