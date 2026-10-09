#!/usr/bin/env bash
# =============================================================================
# 11_mondial.sh  —  Load Mondial (world geography) into PostgreSQL
# Source: postgres/data/mondial/mondial-schema.psql + mondial-inputs.psql
# Target: database mondial, schema mondial
# =============================================================================
set -euo pipefail

DIR="/source/mondial"

echo "------------------------------------------------------"
echo "  Loading: mondial.mondial  (World geography, 47 tables)"
echo "------------------------------------------------------"

{
    echo "SET search_path TO mondial;"
    cat "$DIR/mondial-schema.psql"
    cat "$DIR/mondial-inputs.psql"
} | psql \
    -v ON_ERROR_STOP=1 \
    --quiet \
    --username "$POSTGRES_USER" \
    --dbname   "mondial"

echo "mondial loaded  ✓"
