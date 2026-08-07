#!/usr/bin/env bash
# =============================================================================
# 05_menagerie.sh  —  Load Menagerie (the MySQL tutorial DB) into MySQL
# Source: mysql/data/menagerie/cr_pet_tbl.sql, cr_event_tbl.sql  (DDL)
#                              pet.txt, event.txt                (tab-separated data)
#                              ins_puff_rec.sql                  (one extra pet)
# Target: database menagerie
#
# This is the dataset from the MySQL manual's "Getting Started" tutorial, so its
# scripts are written for an interactive `mysql` session:
#
#   * `LOAD DATA LOCAL INFILE 'pet.txt'` — needs local_infile enabled on both
#     the client and the server, and resolves the path client-side. Rather than
#     loosen the server setting for 19 rows, load_pet_tbl.sql is skipped and the
#     two .txt files are turned into INSERT statements here (tsv_to_inserts).
#     The `\N` placeholder in pet.txt and the missing 4th field on two event.txt
#     rows both become NULL, which is what LOAD DATA would have done.
#   * The DDL uses `#` comments, which MySQL accepts — so cr_pet_tbl.sql and
#     cr_event_tbl.sql run unmodified.
#
# The same dataset is also built for SQLite (sqlite/init/menagerie_sqlite.sql),
# where it had to be rewritten by hand instead.
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

BASE="/source/menagerie"

echo "------------------------------------------------------"
echo "  Loading: menagerie  (Pet Tutorial DB, 2 tables)"
echo "------------------------------------------------------"

# tsv_to_inserts <table> <columns> <file>  →  INSERT statements on stdout
# The quote and backslash characters are built with sprintf rather than written
# as escapes: they would otherwise have to survive shell quoting *and* awk's own
# string-escape pass, which is where this kind of one-liner usually breaks.
# Neither .txt file contains a backslash other than the \N null marker; if that
# ever changes, the warning fires instead of silently emitting a MySQL escape.
tsv_to_inserts() {
    awk -F'\t' -v tbl="$1" -v n="$2" '
        BEGIN { q = sprintf("%c", 39); bs = sprintf("%c", 92); nul = bs "N" }
        {
            out = ""
            for (i = 1; i <= n; i++) {
                if (i > NF || $i == nul) {
                    out = out "NULL"
                } else {
                    v = $i
                    if (index(v, bs) > 0)
                        print "  WARNING: backslash in " tbl " line " FNR " field " i > "/dev/stderr"
                    gsub(q, q q, v)
                    out = out q v q
                }
                if (i < n) out = out ", "
            }
            printf "INSERT INTO %s VALUES (%s);\n", tbl, out
        }' "$3"
}

my -e "DROP DATABASE IF EXISTS menagerie;
       CREATE DATABASE menagerie DEFAULT CHARACTER SET utf8mb4;"

echo "  → Tables (cr_pet_tbl.sql, cr_event_tbl.sql)..."
my --database=menagerie < "${BASE}/cr_pet_tbl.sql"
my --database=menagerie < "${BASE}/cr_event_tbl.sql"

echo "  → Data (pet.txt, event.txt converted from TSV, + ins_puff_rec.sql)..."
{
    tsv_to_inserts pet   6 "${BASE}/pet.txt"
    tsv_to_inserts event 4 "${BASE}/event.txt"
    cat "${BASE}/ins_puff_rec.sql"
} | my --database=menagerie || { seed_failed menagerie; exit 1; }

report menagerie "
    SELECT 'pet' AS table_name, COUNT(*) AS rows_loaded FROM pet
    UNION ALL SELECT 'event', COUNT(*) FROM event;"

echo "menagerie loaded  ✓  (pet 9, event 10 expected)"
)
