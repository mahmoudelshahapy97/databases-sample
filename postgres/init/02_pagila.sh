#!/usr/bin/env bash
# =============================================================================
# 02_pagila.sh  —  Load Pagila (DVD rental store) into PostgreSQL
# Source: postgres/data/pagila/pagila-schema.sql  (DDL — tables, views, functions)
#         postgres/data/pagila/pagila-data.sql    (data — COPY FROM stdin, ~12 MB)
# Target: database pagila, schema pagila
#
# Adjustments for PostgreSQL 16:
#   - DEFAULT uuidv7() → DEFAULT gen_random_uuid()
#   - GENERATED ALWAYS AS (...) VIRTUAL → GENERATED ALWAYS AS (...) STORED
#   - Replace public.vector(20) → text for pgvector compatibility
#   - Remove PG 17 transaction_timeout setting
#
# Schema relocation: unlike the other sources, pagila is a pg_dump output and
# fully qualifies every object as public.<name> (600 references in the schema
# file, 83 in the data file). Rewriting `public.` → `pagila.` therefore moves
# the whole dataset; verified to have zero false positives in both files (no
# occurrence of `public.` is preceded by a word character). The dump's own
# set_config('search_path','') is rewritten too so the handful of unqualified
# references it emits resolve to pagila as well.
# =============================================================================
set -euo pipefail

SCHEMA_FILE="/source/pagila/pagila-schema.sql"
DATA_FILE="/source/pagila/pagila-data.sql"

echo "------------------------------------------------------"
echo "  Loading: pagila.pagila  (DVD Rental Store, 15 tables)"
echo "------------------------------------------------------"

# Keep the public.vector(20) rewrite ahead of the blanket public.→pagila. rule;
# sed applies -e expressions in order, so the specific case wins.
relocate() {
    sed \
        -e 's/DEFAULT uuidv7()/DEFAULT gen_random_uuid()/g' \
        -e 's/VIRTUAL/STORED/g' \
        -e 's/public\.vector(20)/text/g' \
        -e '/CREATE EXTENSION IF NOT EXISTS vector/d' \
        -e '/COMMENT ON EXTENSION vector/d' \
        -e '/USING hnsw/d' \
        -e '/transaction_timeout/d' \
        -e "s/set_config('search_path', '', false)/set_config('search_path', 'pagila, public', false)/" \
        -e 's/public\./pagila./g' \
        "$1"
}

echo "  → Schema (tables, views, triggers, PL/pgSQL functions)..."
relocate "$SCHEMA_FILE" \
| psql \
    -v ON_ERROR_STOP=1 \
    --username "$POSTGRES_USER" \
    --dbname   "pagila"

echo "  → Data (COPY format, ~15 000 rows)..."
relocate "$DATA_FILE" \
| psql \
    -v ON_ERROR_STOP=1 \
    --username "$POSTGRES_USER" \
    --dbname   "pagila"

echo "pagila loaded  ✓  (film, actor, rental, payment, customer, inventory, …)"
