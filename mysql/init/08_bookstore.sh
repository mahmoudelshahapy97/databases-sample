#!/usr/bin/env bash
# =============================================================================
# 08_bookstore.sh  —  Load Bookstore (online book sales) into MySQL
# Source: mysql/data/bookstore/bookstore.sql
# Target: database bookstore
# =============================================================================
(
set -uo pipefail
. /seed/lib.sh

echo "------------------------------------------------------"
echo "  Loading: bookstore  (Online book sales, 11 tables)"
echo "------------------------------------------------------"

if ! my < /source/bookstore/bookstore.sql; then
    seed_failed bookstore
    exit 1
fi

report bookstore "
    SELECT 'publisher'   AS table_name, COUNT(*) AS rows_loaded FROM publisher
    UNION ALL SELECT 'book',        COUNT(*) FROM book
    UNION ALL SELECT 'genre',       COUNT(*) FROM genre
    UNION ALL SELECT 'bookgenre',   COUNT(*) FROM bookgenre
    UNION ALL SELECT 'author',      COUNT(*) FROM author
    UNION ALL SELECT 'bookauthor',  COUNT(*) FROM bookauthor
    UNION ALL SELECT 'customer',    COUNT(*) FROM customer
    UNION ALL SELECT 'address',     COUNT(*) FROM address
    UNION ALL SELECT 'wishlist',    COUNT(*) FROM wishlist
    UNION ALL SELECT 'orders',      COUNT(*) FROM orders
    UNION ALL SELECT 'order_book',  COUNT(*) FROM order_book;"

echo "bookstore loaded  ✓"
)
