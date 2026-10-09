#!/usr/bin/env bash
# =============================================================================
# 07_bookstore.sh  —  Load Bookstore (online book sales) into Oracle XE
# Source: oracle/data/bookstore/bookstore_oracle.sql
# Schema: BOOKSTORE user inside XEPDB1
# =============================================================================
set -euo pipefail

PASS="${ORACLE_PASSWORD}"
SRC="/source/bookstore/bookstore_oracle.sql"

echo "======================================================"
echo "  Oracle: Setting up BOOKSTORE schema"
echo "======================================================"

# ── Step 1: Create BOOKSTORE user as SYSTEM ──────────────────────────────────
sqlplus -s "system/${PASS}@//localhost/XEPDB1" <<-EOF
    WHENEVER SQLERROR EXIT SQL.SQLCODE
    WHENEVER OSERROR EXIT FAILURE

    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM dba_users WHERE username = 'BOOKSTORE';
        IF v_count > 0 THEN
            EXECUTE IMMEDIATE 'DROP USER bookstore CASCADE';
        END IF;
    END;
    /

    CREATE USER bookstore IDENTIFIED BY "${PASS}"
        DEFAULT TABLESPACE USERS
        TEMPORARY TABLESPACE TEMP
        QUOTA UNLIMITED ON USERS;

    GRANT CONNECT, RESOURCE, CREATE VIEW, CREATE SEQUENCE,
          CREATE TRIGGER TO bookstore;

    EXIT;
EOF

echo "  BOOKSTORE user created."

# ── Step 2: Load schema + data as BOOKSTORE ──────────────────────────────────
echo "  Loading Bookstore schema + data (11 tables)..."
sqlplus -s "bookstore/${PASS}@//localhost/XEPDB1" <<-EOF
    WHENEVER SQLERROR EXIT SQL.SQLCODE
    WHENEVER OSERROR EXIT FAILURE
    @${SRC}
    EXIT;
EOF

echo "Bookstore Oracle loaded  ✓  (11 tables: publisher, book, genre, author, customer,"
echo "                              address, wishlist, orders + link tables)"
