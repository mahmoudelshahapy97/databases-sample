#!/usr/bin/env bash
# =============================================================================
# 00_create_dbs.sh  —  PostgreSQL database + schema creation
# Runs first (alphabetical order) inside /docker-entrypoint-initdb.d
# =============================================================================
# One database per dataset, and inside each database a schema named after the
# dataset rather than everything piling into `public`.
#
# The ALTER DATABASE … SET search_path is what makes that ergonomic: every
# connection to `chinook` starts with search_path = chinook, public. That
# applies to the 01_…06_ loaders below (they connect after this script runs)
# and to clients afterwards, so no query has to schema-qualify anything.
# `public` is kept as a fallback so extensions installed there stay reachable.
# =============================================================================
set -euo pipefail

DATASETS="chinook pagila employees northwind ecommerce world booking healthcare bookstore"

echo "======================================================"
echo "  PostgreSQL: creating 9 databases, one schema each"
echo "======================================================"

for db in $DATASETS; do
    # CREATE DATABASE cannot run inside a transaction block, hence its own call
    psql -v ON_ERROR_STOP=1 \
         --username "$POSTGRES_USER" \
         --dbname   "postgres" \
         --quiet -c "CREATE DATABASE ${db};"

    psql -v ON_ERROR_STOP=1 \
         --username "$POSTGRES_USER" \
         --dbname   "$db" \
         --quiet <<-EOSQL
        CREATE SCHEMA ${db} AUTHORIZATION ${POSTGRES_USER};
        ALTER DATABASE ${db} SET search_path TO ${db}, public;
EOSQL

    echo "  database ${db}  →  schema ${db}  (search_path default)  ✓"
done

echo "All 9 databases and schemas created."
