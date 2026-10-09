#!/usr/bin/env bash
# =============================================================================
# 99_done.sh  —  Mark PostgreSQL seeding as complete
# Runs last (alphabetical order) inside /docker-entrypoint-initdb.d
# =============================================================================
# Postgres has no resumable seeding hook: /docker-entrypoint-initdb.d runs only
# against an empty PGDATA. If any loader above fails, the entrypoint aborts, the
# restart policy brings the container back onto a PGDATA that is no longer
# empty, and the init hook is skipped from then on — leaving a half-seeded
# server that answers connections perfectly happily.
#
# This marker is the difference between that failure being loud and being
# invisible. It is written only if every loader before it succeeded, and the
# healthcheck in docker-compose.yml requires it, so a partial seed reports
# UNHEALTHY and `docker compose up -d --wait` fails instead of returning
# success on incomplete data.
#
# It lives in PGDATA on purpose: it has to survive restarts and disappear
# together with the data it vouches for, so wiping the volume is all it takes
# to get a clean retry.
#
#   docker compose stop postgres
#   docker volume rm multidb_postgres_data
#   docker compose up -d postgres
# =============================================================================
set -euo pipefail

marker="${PGDATA:-/var/lib/postgresql/data}/.seed_complete"
: > "$marker"

echo "======================================================"
echo "  PostgreSQL: all 10 databases seeded  ✓"
echo "  marker: ${marker}"
echo "======================================================"
