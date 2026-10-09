#!/usr/bin/env bash
# =============================================================================
# 04_northwind.sh  —  Load Northwind (classic ERP) into PostgreSQL
# Source: postgres/data/northwind/northwind.sql
# Target: database northwind, schema northwind
#
# Fixes applied:
#   1. N'value' → 'value'   (T-SQL unicode prefix not valid in PG)
#   2. Skip DROP DATABASE / CREATE DATABASE ... WITH ... ; (multi-line block,
#      hardcoded "owner = hho" and all) / \connect  (already on target DB)
#
# The source never schema-qualifies anything, so SET search_path places every
# object in the northwind schema.
# =============================================================================
set -euo pipefail

SRC="/source/northwind/northwind.sql"

echo "------------------------------------------------------"
echo "  Loading: northwind.northwind  (Classic ERP, 13 tables)"
echo "------------------------------------------------------"

{
    echo "SET search_path TO northwind;"
    sed \
        -e 's/\r$//' \
        -e "s/N'/'/g" \
        -e '/^DROP DATABASE/d' \
        -e '/^CREATE DATABASE/,/;$/d' \
        -e '/^\\\\connect/d' \
        -e '/^\\\\c /d' \
        "$SRC"
} | psql \
    -v ON_ERROR_STOP=1 \
    --username "$POSTGRES_USER" \
    --dbname   "northwind"

echo "northwind loaded  ✓  (Customer, Employee, Order, Product, Supplier,"
echo "                       Category, Region, Territory, …)"
