#!/usr/bin/env bash
# =============================================================================
# 01_chinook.sh  —  Load Chinook (music store) into MySQL
# Source: mysql/data/chinook/Chinook_MySql.sql
# Target: database chinook
#
# In MySQL a database *is* the namespace — there is no second schema level — so
# one database per dataset is the equivalent of the named schemas used on
# PostgreSQL/SQL Server and of one .db file per dataset on SQLite.
#
# The only edit: upstream creates the database as `Chinook`. Database names are
# case-sensitive on Linux, so it is lower-cased to `chinook` to match every
# other engine here (and the `world`/`sakila`/`northwind` scripts, which are
# already lower-case). Table names are left exactly as upstream ships them.
#
# The whole body runs inside ( … ): the MySQL entrypoint *executes* an init
# script that carries the executable bit and *sources* one that does not, and a
# bind mount from Windows does not reliably preserve that bit. Sourced, a
# top-level `set -u` would leak into the entrypoint's own shell and could abort
# container init long after this script finished. The subshell confines it.
# =============================================================================
(
set -uo pipefail

. /seed/lib.sh

SRC="/source/chinook/Chinook_MySql.sql"

echo "------------------------------------------------------"
echo "  Loading: chinook  (Digital Music Store, 11 tables)"
echo "------------------------------------------------------"

if ! sed 's/`Chinook`/`chinook`/g' "$SRC" | my; then
    seed_failed chinook
    exit 1
fi

report chinook "
    SELECT 'Artist' AS table_name, COUNT(*) AS rows_loaded FROM Artist
    UNION ALL SELECT 'Album',         COUNT(*) FROM Album
    UNION ALL SELECT 'Track',         COUNT(*) FROM Track
    UNION ALL SELECT 'Genre',         COUNT(*) FROM Genre
    UNION ALL SELECT 'MediaType',     COUNT(*) FROM MediaType
    UNION ALL SELECT 'Customer',      COUNT(*) FROM Custome
    UNION ALL SELECT 'Employee',      COUNT(*) FROM Employee
    UNION ALL SELECT 'Invoice',       COUNT(*) FROM Invoice
    UNION ALL SELECT 'InvoiceLine',   COUNT(*) FROM InvoiceLine
    UNION ALL SELECT 'Playlist',      COUNT(*) FROM Playlist
    UNION ALL SELECT 'PlaylistTrack', COUNT(*) FROM PlaylistTrack;"

echo "chinook loaded  ✓  (~15 600 rows)"
)
