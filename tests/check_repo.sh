#!/usr/bin/env bash
# Static consistency checks: no containers, runs in seconds.
set -uo pipefail
cd "$(dirname "$0")/.."

FAILED=0
fail() { echo "FAIL: $*"; FAILED=1; }

# Hand-written DDL in an init dir gets executed by the image entrypoint against the
# default database (see docker-compose.yml); only numbered .sh loaders belong there.
for d in postgres/init mysql/init; do
    stray=$(find "$d" -maxdepth 1 -type f -name '*.sql' | head -1)
    [ -z "$stray" ] || fail "$d contains a .sql file ($stray)"
done

# Every dataset verify.sh checks must have a loader in that engine's init dir.
for engine in postgres mysql; do
    case $engine in
        postgres) fn=verify_postgres ;;
        mysql)    fn=verify_mysql ;;
    esac
    dbs=$(awk -v fn="$fn" '$0 ~ "^"fn"\(\)" {f=1} f && /for db in/ {sub(/.*for db in /,""); sub(/; do.*/,""); print; exit}' verify.sh)
    [ -n "$dbs" ] || { fail "could not read dataset list for $engine from verify.sh"; continue; }
    for db in $dbs; do
        ls "$engine"/init/*_"$db".sh >/dev/null 2>&1 || fail "$engine: verify.sh expects '$db' but no init/*_$db.sh exists"
    done
done

# Loaders must be executable-agnostic but syntactically valid.
while IFS= read -r f; do
    bash -n "$f" || fail "syntax error in $f"
done < <(find . -name '*.sh' -not -path './.git/*')

for f in tools/*.py; do
    python3 -m py_compile "$f" || fail "py_compile $f"
done

[ "$FAILED" -eq 0 ] && echo "check_repo: OK"
exit "$FAILED"
