#!/usr/bin/env bash
# =============================================================================
# 10_bookstore.sh  —  Load Bookstore (online book sales) into PostgreSQL
# Source: postgres/data/bookstore/bookstore_pg.sql
# Target: database bookstore, schema bookstore
# =============================================================================
set -euo pipefail

SRC="/source/bookstore/bookstore_pg.sql"

echo "------------------------------------------------------"
echo "  Loading: bookstore.bookstore  (Online book sales, 11 tables)"
echo "------------------------------------------------------"

{
    echo "SET search_path TO bookstore;"
    cat "$SRC"
} | psql \
    -v ON_ERROR_STOP=1 \
    --username "$POSTGRES_USER" \
    --dbname   "bookstore"

echo "bookstore loaded  ✓  (publisher, book, genre, bookgenre, author, bookauthor,"
echo "                       customer, address, wishlist, orders, order_book)"
