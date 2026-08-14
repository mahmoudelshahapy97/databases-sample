#!/usr/bin/env bash
# =============================================================================
# 06_healthcare.sh  —  Load Healthcare (OpenEMR core) into Oracle XE
# Source: oracle/data/healthcare/healthcare_oracle.sql
# Schema: HEALTHCARE user inside XEPDB1
# =============================================================================
set -euo pipefail

PASS="${ORACLE_PASSWORD}"
SRC="/source/healthcare/healthcare_oracle.sql"

echo "======================================================"
echo "  Oracle: Setting up HEALTHCARE schema"
echo "======================================================"

# ── Step 1: Create HEALTHCARE user as SYSTEM ──────────────────────────────────
sqlplus -s "system/${PASS}@//localhost/XEPDB1" <<-EOF
    WHENEVER SQLERROR EXIT SQL.SQLCODE
    WHENEVER OSERROR EXIT FAILURE

    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM dba_users WHERE username = 'HEALTHCARE';
        IF v_count > 0 THEN
            EXECUTE IMMEDIATE 'DROP USER healthcare CASCADE';
        END IF;
    END;
    /

    CREATE USER healthcare IDENTIFIED BY "${PASS}"
        DEFAULT TABLESPACE USERS
        TEMPORARY TABLESPACE TEMP
        QUOTA UNLIMITED ON USERS;

    GRANT CONNECT, RESOURCE, CREATE VIEW, CREATE SEQUENCE,
          CREATE TRIGGER TO healthcare;

    EXIT;
EOF

echo "  HEALTHCARE user created."

# ── Step 2: Load schema + data as HEALTHCARE ──────────────────────────────────
echo "  Loading Healthcare schema + data (12 tables)..."
sqlplus -s "healthcare/${PASS}@//localhost/XEPDB1" <<-EOF
    WHENEVER SQLERROR EXIT SQL.SQLCODE
    WHENEVER OSERROR EXIT FAILURE
    @${SRC}
    EXIT;
EOF

echo "Healthcare Oracle loaded  ✓  (facility 3, users 5, patient_data 10,"
echo "                               appointments 8, encounters 8, prescriptions 6)"
