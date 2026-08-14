#!/usr/bin/env bash
# =============================================================================
# 03_northwind.sh  —  Load Northwind (classic ERP) into MySQL
# Source: mysql/data/northwind/northwind.sql
# Target: database northwind
#
# The MySQL script already creates its own lower-case `northwind` database,
# USEs it, and sets the session sql_mode it needs. `SalesOrder` is what the
# other ports call `Order` — MySQL reserves that word.
#
# ── One patch, for MySQL 8.4 ─────────────────────────────────────────────────
# SalesOrder declares PRIMARY KEY (orderId, custId), and OrderDetail's foreign
# key references SalesOrder(orderId) — only the *prefix* of that key, so the
# referenced column is not unique. InnoDB used to allow that; 8.4 does not, and
# rejects the CREATE TABLE with
#
#   ERROR 6125 (HY000): Failed to add the foreign key constraint. Missing
#   unique key for constraint 'OrderDetail_ibfk_1' in the referenced table
#   'SalesOrder'
#
# which aborts the whole script — 12 tables created, zero rows loaded, because
# every INSERT comes after this point in the file.
#
# The fix is to declare what is already true: orderId is AUTO_INCREMENT, so it
# is unique on its own, and adding a UNIQUE KEY on it satisfies 8.4 without
# changing the data model or the composite primary key.
#
# The whole body runs inside ( … ): the MySQL entrypoint *executes* an init
# script that carries the executable bit and *sources* one that does not, and a
# bind mount from Windows does not reliably preserve that bit. Sourced, a
# top-level `set -u` would leak into the entrypoint's own shell and could abort
# container init long after this script finished. The subshell confines it.
# =============================================================================
(
set -uo pipefail

. /seed/lib.sh

SRC="/source/northwind/northwind.sql"

echo "------------------------------------------------------"
echo "  Loading: northwind  (Classic ERP, 13 tables)"
echo "------------------------------------------------------"

patched="/tmp/northwind_patched.sql"
sed 's/,PRIMARY KEY (orderId,custId)/,PRIMARY KEY (orderId,custId)\n  ,UNIQUE KEY uq_salesorder_orderid (orderId)/' \
    "$SRC" > "$patched"

# Fail fast if upstream ever changes shape under us, rather than silently
# loading a schema whose foreign key is gone.
if ! grep -q "uq_salesorder_orderid" "$patched"; then
    echo "  ERROR: could not add the UNIQUE KEY to SalesOrder."
    echo "         Upstream's 'PRIMARY KEY (orderId,custId)' line was not found."
    exit 1
fi

if ! my < "$patched"; then
    rm -f "$patched"
    seed_failed northwind
    exit 1
fi
rm -f "$patched"

report northwind "
    SELECT 'Customer' AS table_name, COUNT(*) AS rows_loaded FROM Custome
    UNION ALL SELECT 'Employee',    COUNT(*) FROM Employee
    UNION ALL SELECT 'Product',     COUNT(*) FROM Product
    UNION ALL SELECT 'Category',    COUNT(*) FROM Category
    UNION ALL SELECT 'Supplier',    COUNT(*) FROM Supplie
    UNION ALL SELECT 'Shipper',     COUNT(*) FROM Shippe
    UNION ALL SELECT 'SalesOrder',  COUNT(*) FROM SalesOrde
    UNION ALL SELECT 'OrderDetail', COUNT(*) FROM OrderDetail
    UNION ALL SELECT 'Region',      COUNT(*) FROM Region
    UNION ALL SELECT 'Territory',   COUNT(*) FROM Territory;"

echo "northwind loaded  ✓"
)
