#!/usr/bin/env bash
# =============================================================================
# 05_booking.sh  —  Load Booking (Hotel Reservation) into Oracle XE
# Source: oracle/data/booking/booking_oracle.sql
# Schema: BOOKING user inside XEPDB1
# =============================================================================
set -euo pipefail

PASS="${ORACLE_PASSWORD}"
SRC="/source/booking/booking_oracle.sql"

echo "======================================================"
echo "  Oracle: Setting up BOOKING schema"
echo "======================================================"

# ── Step 1: Create BOOKING user as SYSTEM ─────────────────────────────────────
sqlplus -s "system/${PASS}@//localhost/XEPDB1" <<-EOF
    WHENEVER SQLERROR EXIT SQL.SQLCODE
    WHENEVER OSERROR EXIT FAILURE

    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM dba_users WHERE username = 'BOOKING';
        IF v_count > 0 THEN
            EXECUTE IMMEDIATE 'DROP USER booking CASCADE';
        END IF;
    END;
    /

    CREATE USER booking IDENTIFIED BY "${PASS}"
        DEFAULT TABLESPACE USERS
        TEMPORARY TABLESPACE TEMP
        QUOTA UNLIMITED ON USERS;

    GRANT CONNECT, RESOURCE, CREATE VIEW TO booking;

    EXIT;
EOF

echo "  BOOKING user created."

# ── Step 2: Load schema + data as BOOKING ─────────────────────────────────────
echo "  Loading Booking schema + data (~25 reservations)..."
sqlplus -s "booking/${PASS}@//localhost/XEPDB1" <<-EOF
    WHENEVER SQLERROR EXIT SQL.SQLCODE
    WHENEVER OSERROR EXIT FAILURE
    @${SRC}
    EXIT;
EOF

echo "Booking Oracle loaded  ✓  (Room 18, Amenity 3, Guest 11, Reservation 25)"
