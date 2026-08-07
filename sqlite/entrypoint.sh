#!/bin/sh
# =============================================================================
# entrypoint.sh  —  SQLite database builder + Datasette launcher
#
# On first run, builds one .db file per dataset:
#   1. chinook.db   from Chinook_Sqlite.sql   (~15 600 rows)
#   2. menagerie.db from menagerie_sqlite.sql (19 rows)
#   3. northwind.db from northwind_core.sql   (~3 300 rows)
# On subsequent runs: skips any .db that already exists in the named volume.
# Then starts Datasette to serve all three over HTTP on port 8001.
#
# SQLite has no CREATE SCHEMA — a database file *is* the namespace, so one file
# per dataset is the equivalent of the named schemas used on the other engines.
# Datasette exposes each file as its own top-level database.
# =============================================================================
set -eu

DATA_DIR="/data"

CHINOOK_SRC="/source/chinook/Chinook_Sqlite.sql"
MENAGERIE_SRC="/init/menagerie_sqlite.sql"
NORTHWIND_SRC="/source/northwind/northwind_core.sql"

echo "======================================================"
echo "  SQLite: Building databases"
echo "======================================================"

# build <db name> <source .sql> <description>
build() {
    db="${DATA_DIR}/$1.db"
    src="$2"
    desc="$3"

    if [ -f "$db" ]; then
        echo "  $1.db already exists — skipping build."
        return 0
    fi
    if [ ! -f "$src" ]; then
        echo "  ERROR: source for $1.db not found at $src" >&2
        return 1
    fi

    echo "  Building $1.db ($desc)..."
    # Build to a temp path and move into place, so an interrupted run does not
    # leave a half-populated file that the next start would skip.
    rm -f "${db}.tmp"
    sqlite3 "${db}.tmp" < "$src"
    mv "${db}.tmp" "$db"
    echo "  $1.db ready  ✓  ($(sqlite3 "$db" "SELECT COUNT(*) FROM sqlite_master WHERE type='table';") tables)"
}

build chinook   "$CHINOOK_SRC"   "Digital Music Store — ~15 600 rows"
build menagerie "$MENAGERIE_SRC" "Pet Tutorial DB — 19 rows"
build northwind "$NORTHWIND_SRC" "Classic ERP — ~3 300 rows"

echo "======================================================"
echo "  Starting Datasette on http://0.0.0.0:8001"
echo "  Serving: chinook.db, menagerie.db, northwind.db"
echo "======================================================"

exec datasette serve \
    "${DATA_DIR}/chinook.db" \
    "${DATA_DIR}/menagerie.db" \
    "${DATA_DIR}/northwind.db" \
    --host 0.0.0.0 \
    --port 8001 \
    --cors \
    --setting sql_time_limit_ms 10000 \
    --setting max_returned_rows 5000
