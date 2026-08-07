#!/usr/bin/env bash
# =============================================================================
# lib.sh  —  helpers shared by the mysql/init loaders
# =============================================================================
# Mounted at /seed, deliberately *not* in /docker-entrypoint-initdb.d: the MySQL
# entrypoint executes every .sh and .sql it finds in that directory, so anything
# meant to be sourced by a loader has to live outside it. Same reasoning as
# postgres/assets and oracle/assets.
#
# Connecting during init is the only fiddly part. The server running at that
# point is a *temporary* instance started with --skip-networking, so TCP is not
# available — every client call has to go over the unix socket, and its path
# differs between image variants. mysql_sock() finds whichever one exists.
# =============================================================================

# mysql_sock  →  path of the live server socket
mysql_sock() {
    local s
    for s in "${MYSQL_UNIX_PORT:-}" \
             /var/run/mysqld/mysqld.sock \
             /var/lib/mysql/mysql.sock \
             /tmp/mysql.sock; do
        if [ -n "$s" ] && [ -S "$s" ]; then
            echo "$s"
            return 0
        fi
    done
    echo "ERROR: no MySQL unix socket found — cannot seed." >&2
    return 1
}

# my [args…]  —  mysql client as root against the init-time server.
# MYSQL_PWD keeps the password off the command line, which also avoids the
# "Using a password on the command line interface can be insecure" warning on
# every single call.
my() {
    MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" mysql \
        --socket="$(mysql_sock)" \
        --user=root \
        --default-character-set=utf8mb4 \
        "$@"
}

# report <database> <sql>  —  print a table of exact COUNT(*) values.
# Exact counts, not information_schema estimates: a table that was created but
# never populated has to show as 0 rather than hide behind a stale estimate.
report() {
    my --table --database="$1" -e "$2"
}

# seed_failed <dataset>  —  loud banner for a load that did not complete.
#
# The mysql client stops at the first error but exits non-zero rather than
# taking the container down, so without this a half-loaded dataset would scroll
# past under a "loaded ✓" line. That is exactly how northwind once ended up
# with 12 tables and 0 rows. Init is deliberately *not* aborted: the other
# datasets are independent and stay usable.
seed_failed() {
    echo "!!===================================================================!!"
    echo "!! ERROR: $1 seeding FAILED — see the mysql error(s) above."
    echo "!!"
    echo "!! The database may be partially populated. The other datasets on this"
    echo "!! engine are unaffected. ./verify.sh will show which one is short."
    echo "!!"
    echo "!! To re-seed everything:  docker compose stop mysql"
    echo "!!                         docker volume rm multidb_mysql_data"
    echo "!!                         docker compose up -d mysql"
    echo "!!===================================================================!!"
}
