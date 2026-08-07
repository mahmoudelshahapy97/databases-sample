#!/usr/bin/env bash
# =============================================================================
# 02_sakila.sh  —  Load Sakila (DVD rental store) into MySQL
# Source: mysql/data/sakila/sakila-schema.sql  (DDL, views, triggers, routines)
#                          sakila-data.sql     (data, ~46 000 rows)
# Target: database sakila
#
# Sakila is MySQL's own sample database and the original that PostgreSQL's
# pagila (loaded on the postgres service) was ported from — the same 15-table
# rental model on both engines, which makes it the natural cross-engine
# comparison in this sandbox.
#
# Both files are run unmodified. They create and USE the schema themselves, and
# the DELIMITER directives around the triggers and stored routines are mysql
# *client* commands, which is exactly what they are being piped into.
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

BASE="/source/sakila"

echo "------------------------------------------------------"
echo "  Loading: sakila  (DVD Rental Store, 16 tables + views/routines)"
echo "------------------------------------------------------"

echo "  → Schema (tables, views, triggers, procedures, functions)..."
if ! my < "${BASE}/sakila-schema.sql"; then
    seed_failed sakila
    exit 1
fi

echo "  → Data (~46 000 rows)..."
if ! my < "${BASE}/sakila-data.sql"; then
    seed_failed sakila
    exit 1
fi

report sakila "
    SELECT 'film' AS table_name, COUNT(*) AS rows_loaded FROM film
    UNION ALL SELECT 'actor',     COUNT(*) FROM actor
    UNION ALL SELECT 'customer',  COUNT(*) FROM customer
    UNION ALL SELECT 'inventory', COUNT(*) FROM inventory
    UNION ALL SELECT 'rental',    COUNT(*) FROM rental
    UNION ALL SELECT 'payment',   COUNT(*) FROM payment
    UNION ALL SELECT 'staff',     COUNT(*) FROM staff
    UNION ALL SELECT 'store',     COUNT(*) FROM store;"

echo "sakila loaded  ✓  (film 1000, rental 16 044, payment 16 049 expected)"
)
