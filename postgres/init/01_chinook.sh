#!/usr/bin/env bash
# =============================================================================
# 01_chinook.sh  —  Load Chinook (music store) into PostgreSQL
# Source: postgres/data/chinook/Chinook_PostgreSql.sql
# Target: database chinook, schema chinook
#
# Fixes applied: Strip N'...' unicode string prefix (T-SQL artefact not valid in PG)
#                Skip CREATE DATABASE / \connect lines (DB already created by 00_)
#
# The source never schema-qualifies anything, so the prepended SET search_path
# is all it takes to land every object in the chinook schema.
# =============================================================================
set -euo pipefail

SRC="/source/chinook/Chinook_PostgreSql.sql"

echo "------------------------------------------------------"
echo "  Loading: chinook.chinook  (Digital Music Store, 11 tables)"
echo "------------------------------------------------------"

# sed fixes:
#   1. N'value' → 'value'   (strip T-SQL unicode prefix)
#   2. Drop CREATE DATABASE / DROP DATABASE lines
#   3. Drop \connect / \c  lines  (psql meta-commands not needed — already on target DB)
{
    echo "SET search_path TO chinook;"
    sed \
        -e "s/N'/'/g" \
        -e '/^DROP DATABASE/d' \
        -e '/^CREATE DATABASE/d' \
        -e '/^\\\\connect/d' \
        -e '/^\\\\c /d' \
        "$SRC"
} | psql \
    -v ON_ERROR_STOP=1 \
    --username "$POSTGRES_USER" \
    --dbname   "chinook"

echo "chinook loaded  ✓  (Artist, Album, Track, Genre, MediaType, Customer,"
echo "                     Employee, Invoice, InvoiceLine, Playlist, PlaylistTrack)"
