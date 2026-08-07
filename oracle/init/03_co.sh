#!/usr/bin/env bash
# =============================================================================
# 03_co.sh  —  Load CO (Customer Orders) schema into Oracle XE
# Source: oracle/data/customer_orders/co_create.sql   (DDL + views)
#                                     co_populate.sql (data)
#
# Upstream ships co_install.sql as the entry point, but that script is
# interactive: ACCEPT prompts for password/tablespace/overwrite, SPOOL to a log
# file, and an `exit` at the end. So this script does the co_install.sql job
# itself (create user, grant, set the schema) and then @-calls the two
# non-interactive scripts directly.
#
# Note they are run *unmodified*. Everything SQL*Plus-specific in them (rem,
# SET, Prompt) is valid SQL*Plus — and one of those SET lines matters:
# co_populate.sql sets DEFINE OFF, which stops SQL*Plus treating the `&` in the
# address "No. C54 & 55, G Block" as a substitution variable. Stripping SET
# lines the way 02_hr.sh does would silently corrupt that row.
# =============================================================================
set -euo pipefail

PASS="${ORACLE_PASSWORD}"
CO_BASE="/source/customer_orders"

echo "======================================================"
echo "  Oracle: Setting up CO (Customer Orders) schema"
echo "======================================================"

# ── Step 1: Create the CO user as SYSTEM ──────────────────────────────────────
sqlplus -s "system/${PASS}@//localhost/XEPDB1" <<-EOF
    WHENEVER SQLERROR EXIT SQL.SQLCODE
    WHENEVER OSERROR EXIT FAILURE

    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM dba_users WHERE username = 'CO';
        IF v_count > 0 THEN
            EXECUTE IMMEDIATE 'DROP USER co CASCADE';
        END IF;
    END;
    /

    CREATE USER co IDENTIFIED BY "${PASS}"
        DEFAULT TABLESPACE USERS
        TEMPORARY TABLESPACE TEMP
        QUOTA UNLIMITED ON USERS;

    -- Same privilege set co_install.sql grants, plus ALTER SESSION
    GRANT CREATE SESSION,
          ALTER SESSION,
          CREATE TABLE,
          CREATE VIEW,
          CREATE SEQUENCE,
          CREATE SYNONYM,
          CREATE TRIGGER,
          CREATE TYPE,
          CREATE PROCEDURE,
          CREATE MATERIALIZED VIEW
      TO co;

    EXIT;
EOF

echo "  CO user created."

# ── Step 2: Tables, constraints, indexes, views ───────────────────────────────
echo "  Loading CO DDL (co_create.sql)..."
sqlplus -s "co/${PASS}@//localhost/XEPDB1" <<-EOF
    WHENEVER SQLERROR EXIT SQL.SQLCODE
    WHENEVER OSERROR EXIT FAILURE
    ALTER SESSION SET NLS_LANGUAGE=American;
    ALTER SESSION SET NLS_TERRITORY=America;
    @${CO_BASE}/co_create.sql
    EXIT;
EOF
echo "  CO schema created."

# ── Step 3: Data ─────────────────────────────────────────────────────────────
echo "  Loading CO data (co_populate.sql, ~8 700 rows)..."
sqlplus -s "co/${PASS}@//localhost/XEPDB1" <<-EOF
    WHENEVER SQLERROR EXIT SQL.SQLCODE
    WHENEVER OSERROR EXIT FAILURE
    ALTER SESSION SET NLS_LANGUAGE=American;
    ALTER SESSION SET NLS_TERRITORY=America;
    @${CO_BASE}/co_populate.sql
    COMMIT;
    EXIT;
EOF

# ── Step 4: Verify against upstream's expected counts ─────────────────────────
sqlplus -s "co/${PASS}@//localhost/XEPDB1" <<-'EOF'
    SET HEADING ON
    SET FEEDBACK OFF
    SET PAGESIZE 50
    COLUMN "Table" FORMAT A14
    SELECT 'customers'   AS "Table",  392 AS "expected", COUNT(1) AS "actual" FROM customers
    UNION ALL SELECT 'stores',         23, COUNT(1) FROM stores
    UNION ALL SELECT 'products',       46, COUNT(1) FROM products
    UNION ALL SELECT 'orders',       1950, COUNT(1) FROM orders
    UNION ALL SELECT 'shipments',    1892, COUNT(1) FROM shipments
    UNION ALL SELECT 'order_items',  3914, COUNT(1) FROM order_items
    UNION ALL SELECT 'inventory',     566, COUNT(1) FROM inventory;
    EXIT;
EOF

echo "CO Oracle loaded  ✓  (customers, stores, products, orders, shipments,"
echo "                       order_items, inventory + 4 views)"
