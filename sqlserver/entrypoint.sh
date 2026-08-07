#!/usr/bin/env bash
# =============================================================================
# entrypoint.sh  —  SQL Server 2022 custom entrypoint
#
# 1. Starts SQL Server in the background
# 2. Polls until the server is accepting connections
# 3. Seeds Chinook + Northwind, each into a schema named after the dataset
#    rather than dbo
# 4. Keeps SQL Server running in the foreground
#
# ── Why the two datasets are handled differently ─────────────────────────────
# Chinook_SqlServer.sql qualifies every single object as [dbo].[Name], so
# rewriting [dbo] → [chinook] relocates the whole script. Nothing else needed.
#
# The db-samples northwind.sql is a mix: 8 tables are created unqualified
# (CREATE TABLE "Employee"), the rest plus every view, procedure and FK are
# qualified as dbo/"dbo"/[dbo]. Rewriting the qualified references is easy, but
# the unqualified ones land in whatever the connecting principal's default
# schema is — and `sa` is always dbo, which cannot be changed. So Northwind is
# loaded as a throwaway login whose DEFAULT_SCHEMA is [northwind], and that
# login is dropped again once seeding finishes.
# =============================================================================
set -euo pipefail

SQLCMD="/opt/mssql-tools18/bin/sqlcmd"
PASS="${SA_PASSWORD}"
SEED_LOGIN="nw_seeder"

CHINOOK_SRC="/source/chinook/Chinook_SqlServer.sql"
NORTHWIND_SRC="/source/northwind/northwind.sql"

# ── Start SQL Server in background ───────────────────────────────────────────
echo "======================================================"
echo "  SQL Server: Starting engine..."
echo "======================================================"
/opt/mssql/bin/sqlservr &
MSSQL_PID=$!

# ── Wait for SQL Server to be ready ──────────────────────────────────────────
echo "  Waiting for SQL Server to accept connections..."
MAX_ATTEMPTS=60
ATTEMPT=0
until $SQLCMD -S localhost -U sa -P "$PASS" -No -Q "SELECT 1" > /dev/null 2>&1; do
    ATTEMPT=$((ATTEMPT + 1))
    if [ "$ATTEMPT" -ge "$MAX_ATTEMPTS" ]; then
        echo "ERROR: SQL Server did not become ready after ${MAX_ATTEMPTS} attempts. Exiting."
        exit 1
    fi
    echo "  Attempt ${ATTEMPT}/${MAX_ATTEMPTS} — not ready yet, retrying in 3s..."
    sleep 3
done

echo "  SQL Server is ready!"
$SQLCMD -S localhost -U sa -P "$PASS" -No -Q "SELECT @@VERSION" | head -2

# ── Seed: Chinook + Northwind in parallel ─────────────────────────────────────
# Independent databases on the same engine — load them concurrently instead
# of waiting for one to finish before starting the other.
(
    echo "------------------------------------------------------"
    echo "  Loading: Chinook.chinook  (Digital Music Store, 11 tables)"
    echo "------------------------------------------------------"
    # The script contains its own DROP/CREATE DATABASE [Chinook] and USE
    # [Chinook], which is left intact — that keeps re-seeding idempotent. A
    # CREATE SCHEMA batch is spliced in right after the USE (it has to be alone
    # in its batch, hence the surrounding GOs), and every [dbo] reference is
    # rewritten to [chinook]. Note `master.dbo.sysdatabases` in the DROP guard
    # is spelled `dbo.` without brackets, so it is left untouched.
    {
        sed -e 's/\[dbo\]/[chinook]/g' -e '/^USE \[Chinook\];/q' "$CHINOOK_SRC"
        echo "GO"
        echo "CREATE SCHEMA [chinook];"
        echo "GO"
        sed -e 's/\[dbo\]/[chinook]/g' -e '1,/^USE \[Chinook\];/d' "$CHINOOK_SRC"
    } > /tmp/chinook_schema.sql

    $SQLCMD \
        -S localhost -U sa -P "$PASS" -No \
        -i /tmp/chinook_schema.sql \
        -b 2>&1 | tail -5
    rm -f /tmp/chinook_schema.sql
    echo "Chinook loaded  ✓  (schema: chinook)"
) &
CHINOOK_PID=$!

(
    echo "------------------------------------------------------"
    echo "  Loading: Northwind.northwind  (Classic ERP, 13 tables + procs)"
    echo "------------------------------------------------------"
    # Northwind's script creates no database — do it here, along with the
    # schema and the seeding principal that defaults into it.
    $SQLCMD -S localhost -U sa -P "$PASS" -No -Q "
    IF DB_ID(N'Northwind') IS NULL CREATE DATABASE [Northwind];
    IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'${SEED_LOGIN}')
        CREATE LOGIN [${SEED_LOGIN}] WITH PASSWORD = '${PASS}', CHECK_POLICY = OFF;
    "
    $SQLCMD -S localhost -U sa -P "$PASS" -No -d Northwind -Q "
    IF SCHEMA_ID(N'northwind') IS NULL EXEC('CREATE SCHEMA [northwind]');
    IF DATABASE_PRINCIPAL_ID(N'${SEED_LOGIN}') IS NULL
        CREATE USER [${SEED_LOGIN}] FOR LOGIN [${SEED_LOGIN}] WITH DEFAULT_SCHEMA = [northwind];
    ALTER ROLE db_owner ADD MEMBER [${SEED_LOGIN}];
    "

    # Every 'dbo' in this file is an object reference — as [dbo].[X], "dbo"."X",
    # dbo.X, or inside object_id('dbo.X') — plus one comment. No data value and
    # no system-object reference (master.dbo/msdb.dbo) contains it, so a blanket
    # rewrite is safe here. Unqualified objects land in [northwind] via the
    # seeding login's DEFAULT_SCHEMA.
    sed 's/dbo/northwind/g' "$NORTHWIND_SRC" > /tmp/northwind_schema.sql

    $SQLCMD \
        -S localhost -U "$SEED_LOGIN" -P "$PASS" -No \
        -d Northwind \
        -i /tmp/northwind_schema.sql \
        2>&1 | tail -5
    rm -f /tmp/northwind_schema.sql

    # Drop the throwaway credential — the objects it created are owned by the
    # schema owner (dbo), so nothing depends on it. Non-fatal if it lingers.
    $SQLCMD -S localhost -U sa -P "$PASS" -No -d Northwind \
        -Q "DROP USER [${SEED_LOGIN}];" 2>&1 | tail -2 || \
        echo "  NOTE: could not drop user ${SEED_LOGIN} — harmless, dev only."
    $SQLCMD -S localhost -U sa -P "$PASS" -No \
        -Q "DROP LOGIN [${SEED_LOGIN}];" 2>&1 | tail -2 || \
        echo "  NOTE: could not drop login ${SEED_LOGIN} — harmless, dev only."

    echo "Northwind loaded  ✓  (schema: northwind)"
) &
NORTHWIND_PID=$!

# Collect both statuses without letting `set -e` tear the container down: a
# crash-loop under `restart: unless-stopped` hides the actual error, whereas a
# running-but-unhealthy container can be inspected. /tmp/seed_done is the
# healthcheck gate, so withholding it is what marks the failure.
SEED_RC=0
wait "$CHINOOK_PID"   || { SEED_RC=1; echo "ERROR: Chinook seeding failed.";   }
wait "$NORTHWIND_PID" || { SEED_RC=1; echo "ERROR: Northwind seeding failed."; }

# ── Report what actually landed ───────────────────────────────────────────────
$SQLCMD -S localhost -U sa -P "$PASS" -No -Q "
SET NOCOUNT ON;
SELECT 'Chinook'   AS [database], s.name AS [schema], COUNT(*) AS tables
  FROM Chinook.sys.tables t JOIN Chinook.sys.schemas s ON s.schema_id = t.schema_id
 GROUP BY s.name
UNION ALL
SELECT 'Northwind', s.name, COUNT(*)
  FROM Northwind.sys.tables t JOIN Northwind.sys.schemas s ON s.schema_id = t.schema_id
 GROUP BY s.name;
" || true

if [ "$SEED_RC" -eq 0 ]; then
    echo "======================================================"
    echo "  SQL Server seeding complete!"
    echo "  Chinook.chinook  |  Northwind.northwind"
    echo "======================================================"
    touch /tmp/seed_done
else
    echo "!!===================================================================!!"
    echo "!! SQL Server seeding FAILED — see the errors above."
    echo "!! The engine stays up so you can inspect it, but /tmp/seed_done is"
    echo "!! not written, so the container reports UNHEALTHY."
    echo "!!"
    echo "!! Re-seed:  docker compose stop sqlserver"
    echo "!!           docker volume rm multidb_sqlserver_data"
    echo "!!           docker compose up -d sqlserver"
    echo "!!===================================================================!!"
fi

# ── Keep SQL Server running ───────────────────────────────────────────────────
wait "$MSSQL_PID"
