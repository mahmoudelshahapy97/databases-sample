#!/usr/bin/env bash
# =============================================================================
# entrypoint.sh  —  SQL Server 2022 custom entrypoint
#
# 1. Starts SQL Server in the background
# 2. Polls until the server is accepting connections and every database has
#    finished recovery
# 3. Seeds Chinook + Northwind + Booking + Healthcare, each into a schema named
#    after the dataset rather than dbo — skipping whatever a previous start
#    already loaded
# 4. Keeps SQL Server running in the foreground
#
# ── Why seeding is marker-driven ─────────────────────────────────────────────
# Unlike the postgres/mysql images there is no "run this only on an empty data
# directory" hook here: this entrypoint runs on *every* container start, and
# /var/opt/mssql is a persistent volume. Chinook's upstream script opens with
# DROP DATABASE [Chinook], so re-running it on a restart tears down a perfectly
# good database and rebuilds it. A marker per dataset under $SEED_STATE (which
# lives on that same volume) makes a restart a no-op, while a dataset added
# later still seeds on the next start without disturbing the existing ones.
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
BOOKING_SRC="/source/booking/booking_mssql.sql"
HEALTHCARE_SRC="/source/healthcare/healthcare_mssql.sql"

# One marker file per dataset, on the persistent volume next to the .mdf files.
SEED_STATE="/var/opt/mssql/data/.seeded"
mkdir -p "$SEED_STATE"

already_seeded() { [ -f "$SEED_STATE/$1" ]; }
mark_seeded()    { touch "$SEED_STATE/$1"; }

# Number of databases the engine currently knows by that name — 0 or 1.
db_exists() {
    $SQLCMD -S localhost -U sa -P "$PASS" -No -h -1 -W \
        -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.databases WHERE name = N'$1';" \
        2>/dev/null | tr -cd '0-9'
}

# Remove .mdf/.ldf left behind by a load that died mid-flight — CREATE DATABASE
# refuses to reuse the path and fails with "because it already exists". Guarded
# on the database being unregistered: deleting the files of a live database
# leaves it unrecoverable, which is what an unconditional rm in the Chinook
# block used to do on every single restart.
drop_orphan_files() {
    if [ "$(db_exists "$1")" = "0" ]; then
        rm -f "/var/opt/mssql/data/$1.mdf" "/var/opt/mssql/data/${1}_log.ldf" 2>/dev/null || true
    fi
}

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

# `SELECT 1` only proves master came up. On a restart the seeded databases spend
# a few more seconds replaying their logs, and touching one before it is up
# fails in a way that looks like anything but a timing problem: "Login failed
# for user 'sa'", "Could not find database ID 7", "Database 5 cannot be
# autostarted during server shutdown or startup".
#
# sys.databases.state_desc is no help here — it reads ONLINE for a database
# that has not started yet. DATABASEPROPERTYEX(...,'Collation') is the usable
# signal: it stays NULL until the database is genuinely open for business.
echo "  Waiting for user databases to finish recovery..."
ATTEMPT=0
until [ "$($SQLCMD -S localhost -U sa -P "$PASS" -No -h -1 -W \
            -Q "SET NOCOUNT ON;
                SELECT COUNT(*) FROM sys.databases
                 WHERE state_desc <> 'ONLINE'
                    OR DATABASEPROPERTYEX(name, 'Collation') IS NULL;" \
            2>/dev/null | tr -cd '0-9')" = "0" ]; do
    ATTEMPT=$((ATTEMPT + 1))
    if [ "$ATTEMPT" -ge 30 ]; then
        echo "  WARNING: some databases are still not ready — seeding anyway."
        $SQLCMD -S localhost -U sa -P "$PASS" -No \
            -Q "SELECT name, state_desc FROM sys.databases
                 WHERE state_desc <> 'ONLINE'
                    OR DATABASEPROPERTYEX(name, 'Collation') IS NULL;" || true
        break
    fi
    sleep 3
done
echo "  All databases are online."

# ── Seed: Chinook + Northwind in parallel ─────────────────────────────────────
# Independent databases on the same engine — load them concurrently instead
# of waiting for one to finish before starting the other.
(
    if already_seeded chinook; then
        echo "  Chinook already seeded — skipping."
        exit 0
    fi
    echo "------------------------------------------------------"
    echo "  Loading: Chinook.chinook  (Digital Music Store, 11 tables)"
    echo "------------------------------------------------------"
    drop_orphan_files Chinook

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
    mark_seeded chinook
    echo "Chinook loaded  ✓  (schema: chinook)"
) &
CHINOOK_PID=$!

(
    if already_seeded northwind; then
        echo "  Northwind already seeded — skipping."
        exit 0
    fi
    echo "------------------------------------------------------"
    echo "  Loading: Northwind.northwind  (Classic ERP, 13 tables + procs)"
    echo "------------------------------------------------------"
    # Northwind's script creates no database — do it here, along with the
    # schema and the seeding principal that defaults into it.
    #
    # Dropped first rather than reused: the upstream script's cleanup header
    # guards each DROP TABLE on the *plural* name (object_id('dbo.Categories'))
    # while dropping the singular one ([Category]), so against a populated
    # database it drops an arbitrary subset and then fails to recreate it —
    # the last load left 10 of the 13 tables standing that way. It is only
    # correct against an empty database, and this block only runs when the
    # dataset has no marker, i.e. no good copy exists to protect.
    $SQLCMD -S localhost -U sa -P "$PASS" -No -b -Q "
    IF DB_ID(N'Northwind') IS NOT NULL
    BEGIN
        ALTER DATABASE [Northwind] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
        DROP DATABASE [Northwind];
    END"
    drop_orphan_files Northwind
    $SQLCMD -S localhost -U sa -P "$PASS" -No -b -Q "
    CREATE DATABASE [Northwind];
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

    mark_seeded northwind
    echo "Northwind loaded  ✓  (schema: northwind)"
) &
NORTHWIND_PID=$!

(
    if already_seeded booking; then
        echo "  Booking already seeded — skipping."
        exit 0
    fi
    echo "------------------------------------------------------"
    echo "  Loading: Booking.booking  (Hotel Reservation, 7 tables)"
    echo "------------------------------------------------------"
    $SQLCMD \
        -S localhost -U sa -P "$PASS" -No \
        -i "$BOOKING_SRC" \
        -b 2>&1 | tail -5
    mark_seeded booking
    echo "Booking loaded  ✓  (schema: booking)"
) &
BOOKING_PID=$!

(
    if already_seeded healthcare; then
        echo "  Healthcare already seeded — skipping."
        exit 0
    fi
    echo "------------------------------------------------------"
    echo "  Loading: Healthcare.healthcare  (OpenEMR core, 12 tables)"
    echo "------------------------------------------------------"
    $SQLCMD \
        -S localhost -U sa -P "$PASS" -No \
        -i "$HEALTHCARE_SRC" \
        -b 2>&1 | tail -5
    mark_seeded healthcare
    echo "Healthcare loaded  ✓  (schema: healthcare)"
) &
HEALTHCARE_PID=$!

# Collect all statuses without letting `set -e` tear the container down.
SEED_RC=0
wait "$CHINOOK_PID"    || { SEED_RC=1; echo "ERROR: Chinook seeding failed.";    }
wait "$NORTHWIND_PID"  || { SEED_RC=1; echo "ERROR: Northwind seeding failed.";  }
wait "$BOOKING_PID"    || { SEED_RC=1; echo "ERROR: Booking seeding failed.";    }
wait "$HEALTHCARE_PID" || { SEED_RC=1; echo "ERROR: Healthcare seeding failed."; }

# ── Drop the throwaway Northwind credential ──────────────────────────────────
# Outside the Northwind block on purpose: a run that failed midway leaves the
# login behind, and that run's marker is never written, so a cleanup living
# inside the block would never get another chance to remove it. The objects it
# created are owned by the schema owner (dbo), so nothing depends on it.
if [ "$($SQLCMD -S localhost -U sa -P "$PASS" -No -h -1 -W \
        -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.server_principals WHERE name = N'${SEED_LOGIN}';" \
        2>/dev/null | tr -cd '0-9')" != "0" ]; then
    $SQLCMD -S localhost -U sa -P "$PASS" -No -d Northwind \
        -Q "IF DATABASE_PRINCIPAL_ID(N'${SEED_LOGIN}') IS NOT NULL DROP USER [${SEED_LOGIN}];" 2>&1 | tail -2 || \
        echo "  NOTE: could not drop user ${SEED_LOGIN} — harmless, dev only."
    $SQLCMD -S localhost -U sa -P "$PASS" -No \
        -Q "DROP LOGIN [${SEED_LOGIN}];" 2>&1 | tail -2 || \
        echo "  NOTE: could not drop login ${SEED_LOGIN} — harmless, dev only."
fi

# ── Report what actually landed ───────────────────────────────────────────────
$SQLCMD -S localhost -U sa -P "$PASS" -No -Q "
SET NOCOUNT ON;
SELECT 'Chinook'    AS [database], s.name AS [schema], COUNT(*) AS tables
  FROM Chinook.sys.tables t JOIN Chinook.sys.schemas s ON s.schema_id = t.schema_id
 GROUP BY s.name
UNION ALL
SELECT 'Northwind', s.name, COUNT(*)
  FROM Northwind.sys.tables t JOIN Northwind.sys.schemas s ON s.schema_id = t.schema_id
 GROUP BY s.name
UNION ALL
SELECT 'Booking', s.name, COUNT(*)
  FROM Booking.sys.tables t JOIN Booking.sys.schemas s ON s.schema_id = t.schema_id
 GROUP BY s.name
UNION ALL
SELECT 'Healthcare', s.name, COUNT(*)
  FROM Healthcare.sys.tables t JOIN Healthcare.sys.schemas s ON s.schema_id = t.schema_id
 GROUP BY s.name;
" || true

if [ "$SEED_RC" -eq 0 ]; then
    echo "======================================================"
    echo "  SQL Server seeding complete!"
    echo "  Chinook.chinook  |  Northwind.northwind"
    echo "  Booking.booking  |  Healthcare.healthcare"
    echo "======================================================"
    touch /tmp/seed_done
else
    echo "!!===================================================================!!"
    echo "!! SQL Server seeding FAILED — see the errors above."
    echo "!! The engine stays up so you can inspect it, but /tmp/seed_done is"
    echo "!! not written, so the container reports UNHEALTHY."
    echo "!!"
    echo "!! A dataset that failed has no marker, so restarting the container"
    echo "!! retries just that one:  docker compose restart sqlserver"
    echo "!!"
    echo "!! To force a reload of one that DID succeed, delete its marker:"
    echo "!!   docker exec db_sqlserver rm /var/opt/mssql/data/.seeded/<name>"
    echo "!! To start over completely:"
    echo "!!   docker compose stop sqlserver"
    echo "!!   docker volume rm multidb_sqlserver_data"
    echo "!!   docker compose up -d sqlserver"
    echo "!!===================================================================!!"
fi

# ── Keep SQL Server running ───────────────────────────────────────────────────
wait "$MSSQL_PID"
