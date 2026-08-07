#!/usr/bin/env bash
# =============================================================================
# 06_world.sh  —  Load World (geography) into PostgreSQL
# Source: postgres/data/world/world.sql  (MySQL 8 dump — requires conversion)
#         /seed/world_pg.sql       (hand-written PostgreSQL DDL, see note)
# Target: database world, schema world
#
# world_pg.sql lives in postgres/assets/ (mounted read-only at /seed), *not* in
# /docker-entrypoint-initdb.d — the Postgres entrypoint executes every *.sql it
# finds there, which would also run this DDL standalone against the default
# `postgres` database.
#
# Conversion strategy (on-the-fly via sed/grep):
#   - Create schema from world_pg.sql (pure PostgreSQL DDL)
#   - Extract only INSERT lines from the MySQL dump
#   - Strip backtick quoting from table names in INSERT lines
#   - Wrap the data load in a deferred-constraint transaction to handle the
#     circular FK between country.capital → city.id  and  city.countrycode
# =============================================================================
set -euo pipefail

SRC="/source/world/world.sql"
SCHEMA="/seed/world_pg.sql"

echo "------------------------------------------------------"
echo "  Loading: world.world  (Geography DB, 3 tables)"
echo "------------------------------------------------------"

# ── Step 1: Create the PostgreSQL schema ─────────────────────────────────────
echo "  → Creating tables..."
{
    echo "SET search_path TO world;"
    cat "$SCHEMA"
} | psql \
    -v ON_ERROR_STOP=1 \
    --username "$POSTGRES_USER" \
    --dbname   "world"

# ── Step 2: Load data — deferred constraints allow the country↔city cycle ────
# All three tables' INSERTs (backticks stripped) run inside a single session so
# the deferred-FK transaction actually spans schema load through commit.
echo "  → Loading data (converting from MySQL INSERT format)..."

{
    echo "SET search_path TO world;"
    echo "BEGIN;"
    echo "SET CONSTRAINTS ALL DEFERRED;"
    grep -E "^INSERT INTO \`(country|city|countrylanguage)\`" "$SRC" | sed -e 's/`//g' -e "s/\\\\'/''/g"
    echo "COMMIT;"
    # Sync SERIAL sequence for city.id (MySQL had explicit IDs, SERIAL starts at 1)
    echo "SELECT setval(pg_get_serial_sequence('world.city','id'), (SELECT MAX(id) FROM city));"
} | psql \
    -v ON_ERROR_STOP=1 \
    --username "$POSTGRES_USER" \
    --dbname   "world"

echo "world loaded  ✓  (country: 239 rows, city: 4079 rows, countrylanguage: 984 rows)"
