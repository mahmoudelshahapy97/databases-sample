#!/usr/bin/env bash
# =============================================================================
# 01_chinook.sh  —  Load Chinook (music store) into Oracle XE
# Source: oracle/assets/chinook_oracle_fixed.sql  (baked in at /opt/seed)
#         falls back to oracle/data/chinook/Chinook_Oracle.sql (mounted at /source)
#
# Fixes applied:
#   1. Creates CHINOOK user as SYSTEM
#   2. Runs pre-converted Oracle-compatible DDL + INSERT statements
#
# In Oracle a user *is* a schema, so each dataset already gets its own
# namespace: CHINOOK, HR, CO and SH schemas inside the XEPDB1 pluggable DB.
# =============================================================================
set -euo pipefail

PASS="${ORACLE_PASSWORD}"
SRC="/opt/seed/chinook_oracle_fixed.sql"

echo "======================================================"
echo "  Oracle: Setting up CHINOOK schema"
echo "======================================================"

# ── Step 1: Create CHINOOK user as SYSTEM ─────────────────────────────────────
sqlplus -s "system/${PASS}@//localhost/XEPDB1" <<-EOF
    WHENEVER SQLERROR EXIT SQL.SQLCODE
    WHENEVER OSERROR EXIT FAILURE

    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM dba_users WHERE username = 'CHINOOK';
        IF v_count > 0 THEN
            EXECUTE IMMEDIATE 'DROP USER chinook CASCADE';
        END IF;
    END;
    /

    CREATE USER chinook IDENTIFIED BY "${PASS}"
        DEFAULT TABLESPACE USERS
        TEMPORARY TABLESPACE TEMP
        QUOTA UNLIMITED ON USERS;

    GRANT CONNECT, RESOURCE, CREATE VIEW TO chinook;

    EXIT;
EOF

echo "  CHINOOK user created."

# ── Step 2: Load schema + data as CHINOOK ────────────────────────────────────
echo "  Loading Chinook schema + data (~15 600 rows)..."
if [ -f "$SRC" ]; then
    LOAD_SRC="$SRC"
else
    # Fallback path if mounted elsewhere
    LOAD_SRC="/source/chinook/Chinook_Oracle.sql"
fi

sqlplus -s "chinook/${PASS}@//localhost/XEPDB1" <<-EOF
    WHENEVER SQLERROR EXIT SQL.SQLCODE
    WHENEVER OSERROR EXIT FAILURE
    @${LOAD_SRC}
    EXIT;
EOF

echo "Chinook Oracle loaded  ✓  (Artist, Album, Track, Customer, Employee,"
echo "                            Invoice, InvoiceLine, Playlist, PlaylistTrack)"
