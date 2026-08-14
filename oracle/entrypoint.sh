#!/usr/bin/env bash
# =============================================================================
# entrypoint.sh  —  Oracle XE 21c custom entrypoint
#
# 1. Starts the stock gvenzl entrypoint in the background
# 2. Polls until XEPDB1 is OPEN READ WRITE
# 3. Runs each seeding script in /opt/seed/init, skipping the ones whose schema
#    is already populated
# 4. Writes /tmp/seed_done once everything landed, then hands the container back
#    to the stock entrypoint
#
# ── Why the scripts do not live in /container-entrypoint-initdb.d ────────────
# The gvenzl entrypoint executes every .sh it finds there itself, on the start
# that creates the database. This wrapper would then run the same six scripts a
# second time, concurrently with that first pass — and each script opens with
# DROP USER <schema> CASCADE, so the two passes tear down each other's work
# mid-load. Keeping them in /opt/seed/init leaves exactly one driver: this file.
#
# ── Why "already seeded" is asked per schema ─────────────────────────────────
# This used to be a single check for the CHINOOK user, gating all six scripts.
# CHINOOK is created by the *first* script, so any interruption after it — a
# restart, an OOM kill, one loader failing — left the remaining schemas
# permanently unseeded: the next start saw CHINOOK, declared everything done,
# and skipped them. Adding a dataset to the repo later had the same problem.
#
# What replaces it is a marker per schema under $SEED_STATE, on the same volume
# as the datafiles, written only when that schema's loader exits 0. "The user
# owns some tables" is deliberately *not* the signal on its own: a load that
# dies partway leaves tables behind — booking stopped after 62 of 119 529 rows
# on ORA-01830 and still had all 9 — so a table-count test adopts broken data as
# finished. A marker means the loader ran to completion; anything else re-runs,
# which is safe because every script opens by dropping and recreating its user.
#
# The table count is still checked alongside the marker, to catch the inverse
# case of a marker outliving the data it vouches for.
# =============================================================================
set -uo pipefail

PASS="${ORACLE_PASSWORD:-Oracle123!}"
INIT_DIR="/opt/seed/init"

# One marker per schema, on the persistent volume next to the datafiles, so it
# disappears together with the data it vouches for when the volume is dropped.
SEED_STATE="/opt/oracle/oradata/.seeded"
mkdir -p "$SEED_STATE"

# Start the stock entrypoint in the background — it owns the database lifecycle.
/opt/oracle/container-entrypoint.sh "$@" &
PID=$!

echo "======================================================"
echo "  Oracle: entrypoint wrapper started (PID $PID)"
echo "  Waiting for XEPDB1 to accept connections..."
echo "======================================================"

sysdba() {   # sysdba <sql>  → stdout, headings/feedback suppressed
    sqlplus -s "system/${PASS}@//localhost/XEPDB1" <<SQL 2>&1
SET HEADING OFF FEEDBACK OFF PAGESIZE 0 VERIFY OFF
SET SERVEROUTPUT ON SIZE UNLIMITED
$1
EXIT;
SQL
}

READY=0
for _ in $(seq 1 120); do
    if sysdba "SELECT open_mode FROM v\$pdbs WHERE name = 'XEPDB1';" | grep -q "READ WRITE"; then
        echo "  XEPDB1 is OPEN (READ WRITE) and READY."
        READY=1
        break
    fi
    sleep 3
done

if [ "$READY" -ne 1 ]; then
    echo "ERROR: XEPDB1 did not become ready in time — skipping seeding."
    wait "$PID"
    exit 1
fi

# 05_booking.sh → BOOKING. Every script is named NN_<schema>.sh, so the schema
# it owns is recoverable from the filename — no second list to keep in sync.
schema_of() {
    basename "$1" .sh | sed -e 's/^[0-9]*_//' | tr '[:lower:]' '[:upper:]'
}

# The count is read from a line that is *entirely* digits, not by stripping
# non-digits from the whole output: an ORA-01017 on a failed connection would
# otherwise reduce to "01017" and be read as a populated schema, permanently
# skipping the very load that needs to run. No usable line means "not populated",
# so the worst case is a redundant re-seed rather than a silent skip.
schema_populated() {
    local n
    n=$(sysdba "SELECT COUNT(*) FROM dba_tables WHERE owner = '$1';" \
        | tr -d '[:blank:]\r' | grep -m1 -E '^[0-9]+$')
    [ -n "$n" ] && [ "$n" -gt 0 ]
}

# Skip only what a loader finished *and* whose tables are still there.
already_seeded() { [ -f "$SEED_STATE/$1" ] && schema_populated "$1"; }
mark_seeded()    { touch "$SEED_STATE/$1"; }

SEED_RC=0
RAN=""
SKIPPED=""

for f in "$INIT_DIR"/*.sh; do
    [ -f "$f" ] || continue
    schema=$(schema_of "$f")

    if [ "$schema" = "SH" ] && [ "${ORACLE_SKIP_SH:-false}" = "true" ]; then
        echo "  SH skipped — ORACLE_SKIP_SH=true."
        SKIPPED="$SKIPPED SH"
        continue
    fi

    if already_seeded "$schema"; then
        echo "  ${schema} already seeded — skipping $(basename "$f")."
        SKIPPED="$SKIPPED $schema"
        continue
    fi

    echo "------------------------------------------------------"
    echo "  Running $(basename "$f")  →  schema ${schema}"
    echo "------------------------------------------------------"
    # A loader that fails must not stop the others: the schemas are independent,
    # and one broken dataset should still leave the rest queryable.
    if bash "$f"; then
        mark_seeded "$schema"
        RAN="$RAN $schema"
    else
        rc=$?
        SEED_RC=1
        echo "ERROR: $(basename "$f") failed with exit code ${rc} — ${schema} left unseeded."
    fi
done

# ── Report what actually landed ──────────────────────────────────────────────
echo
echo "======================================================"
echo "  Oracle: schema row counts"
echo "======================================================"
sysdba "
DECLARE
    v_rows NUMBER; v_total NUMBER; v_tables NUMBER;
BEGIN
    FOR s IN (SELECT username FROM dba_users
               WHERE username IN ('CHINOOK','HR','CO','SH','BOOKING','HEALTHCARE')
               ORDER BY username) LOOP
        v_total := 0; v_tables := 0;
        FOR t IN (SELECT table_name FROM dba_tables WHERE owner = s.username
                   AND nested = 'NO' AND (iot_type IS NULL OR iot_type = 'IOT')) LOOP
            EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM \"' || s.username || '\".\"' ||
                              t.table_name || '\"' INTO v_rows;
            v_total := v_total + v_rows; v_tables := v_tables + 1;
        END LOOP;
        DBMS_OUTPUT.PUT_LINE(RPAD(s.username, 14) || LPAD(v_tables, 4) ||
                             ' tables ' || LPAD(v_total, 12) || ' rows');
    END LOOP;
END;
/" 2>&1 | grep -v '^$'

echo
echo "  seeded this start:${RAN:- (none)}"
echo "  skipped:${SKIPPED:- (none)}"

if [ "$SEED_RC" -eq 0 ]; then
    echo "======================================================"
    echo "  Oracle seeding complete!"
    echo "======================================================"
    touch /tmp/seed_done
else
    echo "!!===================================================================!!"
    echo "!! Oracle seeding FAILED for at least one schema — see the errors above."
    echo "!! The engine stays up so you can inspect it, but /tmp/seed_done is"
    echo "!! not written, so the container reports UNHEALTHY."
    echo "!!"
    echo "!! A schema that failed has no marker, so restarting the container"
    echo "!! retries just that one:  docker compose restart oracle"
    echo "!!"
    echo "!! To force a reload of one that DID succeed, delete its marker:"
    echo "!!   docker exec db_oracle rm /opt/oracle/oradata/.seeded/<SCHEMA>"
    echo "!! To start over completely:"
    echo "!!   docker compose stop oracle"
    echo "!!   docker volume rm multidb_oracle_data"
    echo "!!   docker compose up -d oracle"
    echo "!!===================================================================!!"
fi

wait "$PID"
