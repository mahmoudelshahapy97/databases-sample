#!/usr/bin/env bash
# =============================================================================
# 05_ecommerce.sh  —  Load Ecommerce schema into PostgreSQL
# Source: postgres/data/ecommerce/ecommerce.sql
# Target: database ecommerce, schema ecommerce
#
# Native PostgreSQL 13+ script — no dialect fixes required.
# Contains: ~4 000 rows across users, products, orders, payments, inventory
#
# citext: the script's `CREATE EXTENSION IF NOT EXISTS citext;` has no SCHEMA
# clause, so it installs into the first entry of search_path — the ecommerce
# schema — which keeps the extension with the dataset that uses it.
# =============================================================================
set -euo pipefail

SRC="/source/ecommerce/ecommerce.sql"

echo "------------------------------------------------------"
echo "  Loading: ecommerce.ecommerce  (Modern e-commerce, ~10 tables)"
echo "------------------------------------------------------"

{
    echo "SET search_path TO ecommerce;"
    cat "$SRC"
} | psql \
    -v ON_ERROR_STOP=1 \
    --username "$POSTGRES_USER" \
    --dbname   "ecommerce"

echo "ecommerce loaded  ✓  (users, addresses, products, variants, carts,"
echo "                       orders, order_items, payments, shipments, inventory)"
