#!/usr/bin/env bash
# =============================================================================
# 08_mondial.sh  —  Load Mondial (world geography) into Oracle XE
# Source: oracle/data/mondial/mondial-schema.sql + mondial-inputs.sql
# Schema: MONDIAL user inside XEPDB1
# =============================================================================
set -euo pipefail

PASS="${ORACLE_PASSWORD}"
DIR="/source/mondial"
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8

echo "======================================================"
echo "  Oracle: Setting up MONDIAL schema"
echo "======================================================"

sqlplus -s "system/${PASS}@//localhost/XEPDB1" <<-EOF2
    WHENEVER SQLERROR EXIT SQL.SQLCODE
    WHENEVER OSERROR EXIT FAILURE

    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM dba_users WHERE username = 'MONDIAL';
        IF v_count > 0 THEN
            EXECUTE IMMEDIATE 'DROP USER mondial CASCADE';
        END IF;
    END;
    /

    CREATE USER mondial IDENTIFIED BY "${PASS}"
        DEFAULT TABLESPACE USERS
        TEMPORARY TABLESPACE TEMP
        QUOTA UNLIMITED ON USERS;

    GRANT CONNECT, RESOURCE, CREATE VIEW, CREATE TYPE TO mondial;

    EXIT;
EOF2

echo "  MONDIAL user created."

echo "  Loading Mondial schema + data (47 tables)..."
sqlplus -s "mondial/${PASS}@//localhost/XEPDB1" <<-EOF2
    WHENEVER SQLERROR EXIT SQL.SQLCODE
    WHENEVER OSERROR EXIT FAILURE
    SET DEFINE OFF
    SET FEEDBACK OFF
    @${DIR}/mondial-schema.sql
    @${DIR}/mondial-inputs.sql
    EXIT;
EOF2

echo "Mondial Oracle loaded  ✓"
