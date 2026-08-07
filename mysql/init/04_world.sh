#!/usr/bin/env bash
# =============================================================================
# 04_world.sh  —  Load World (geography) into MySQL
# Source: mysql/data/world/world.sql
# Target: database world
#
# This is the one dataset that needs no conversion anywhere in this repo on
# MySQL: the file is a native `mysqldump` of the world database, so it is piped
# in as-is, CREATE DATABASE and all. (The postgres service loads the same file
# the hard way — hand-written DDL plus its INSERT lines with the backticks
# stripped. Worth comparing the two loaders.)
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

SRC="/source/world/world.sql"

echo "------------------------------------------------------"
echo "  Loading: world  (Geography DB, 3 tables)"
echo "------------------------------------------------------"

if ! my < "$SRC"; then
    seed_failed world
    exit 1
fi

report world "
    SELECT 'country' AS table_name, COUNT(*) AS rows_loaded FROM country
    UNION ALL SELECT 'city',            COUNT(*) FROM city
    UNION ALL SELECT 'countrylanguage', COUNT(*) FROM countrylanguage;"

echo "world loaded  ✓  (country 239, city 4079, countrylanguage 984 expected)"
)
