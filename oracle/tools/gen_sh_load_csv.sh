#!/usr/bin/env bash
# =============================================================================
# gen_sh_load_csv.sh  —  regenerate oracle/assets/sh_load_csv.sql
# =============================================================================
# Run on the *host*, not in the container. Nothing at runtime depends on this
# script; it exists so the generated loader can be rebuilt (or audited) instead
# of maintained by hand.
#
#   ./oracle/tools/gen_sh_load_csv.sh        # from the databases/ directory
#
# Every column name in the output comes from the first line of the matching CSV
# file, which is why the INSERT lists are guaranteed to line up with the tables
# sh_create.sql builds — the headers and the DDL are generated from the same
# upstream schema. Hand-typing ~90 column names would not have that property.
# =============================================================================
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
DB_ROOT="$(cd "${HERE}/../.." && pwd)"
SRC="${DB_ROOT}/oracle/data/sales_history"
OUT="${DB_ROOT}/oracle/assets/sh_load_csv.sql"

[ -d "$SRC" ] || { echo "ERROR: $SRC not found" >&2; exit 1; }

# Load order is irrelevant to correctness (all constraints are disabled at the
# point sh_populate.sql calls this), so it runs smallest-first to surface any
# problem before the 71 MB sales.csv.
TABLES="times promotions customers costs sales supplementary_demographics"

{
cat <<'HDR'
-- =============================================================================
-- sh_load_csv.sql  --  Bulk-load the six SH (Sales History) CSV data files
-- =============================================================================
-- GENERATED FILE -- produced by oracle/tools/gen_sh_load_csv.sh from the CSV
-- headers in oracle/data/sales_history/. Re-run the generator
-- instead of editing by hand.
--
-- WHY THIS FILE EXISTS
--   Upstream sh_populate.sql loads these tables with SQLcl's `LOAD <table>
--   <file>.csv` command. SQLcl is a separate Java tool that is not present in
--   the gvenzl/oracle-xe image, so 04_sh.sh rewrites those six LOAD lines into
--   a single @-call to this script, which does the same work with external
--   tables (a core database feature -- no extra binaries required).
--
-- ASSUMPTIONS
--   * Directory object SH_CSV_DIR points at /source/sales_history
--     and SH has READ on it (created by 04_sh.sh as SYSTEM).
--   * Called from sh_populate.sql at the point where all table constraints are
--     still DISABLED and the bitmap indexes have not been created yet.
--   * The CSV mount is read-only, hence NOBADFILE / NOLOGFILE / NODISCARDFILE.
--
-- HOW THE CONVERSION WORKS
--   Each staging column is VARCHAR2 and each INSERT relies on implicit
--   conversion to the real column type, driven by the NLS settings below. The
--   longest line in any of these CSVs is 756 bytes, so 1000 is ample.
--   LRTRIM matters: sales.csv pads its last field with trailing spaces.
--   SKIP 1 discards the header row.
-- =============================================================================

SET DEFINE OFF
SET ECHO OFF
SET FEEDBACK 1

ALTER SESSION SET NLS_LANGUAGE           = American;
ALTER SESSION SET NLS_TERRITORY          = America;
ALTER SESSION SET NLS_DATE_FORMAT        = 'YYYY-MM-DD';
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,';
HDR

for tbl in $TABLES; do
  [ -f "$SRC/$tbl.csv" ] || { echo "ERROR: $SRC/$tbl.csv not found" >&2; exit 1; }

  hdr=$(head -1 "$SRC/$tbl.csv" | tr -d '"\r')
  cols=$(echo "$hdr" | tr ',' '\n')
  ext_defs=$(echo "$cols" | awk '{ printf "%s   %-30s VARCHAR2(1000)", (NR>1 ? ",\n" : ""), $0 }')
  fld_list=$(echo "$cols" | awk '{ printf "%s        %-30s CHAR(1000)", (NR>1 ? ",\n" : ""), $0 }')
  ins_list=$(echo "$cols" | awk '{ printf "%s%s", (NR>1 ? ", " : ""), $0 }' | fold -s -w 68 | sed 's/^/          /')
  n=$(echo "$cols" | wc -l)

cat <<EOF

-- ---------------------------------------------------------------------------
-- $tbl  <-  $tbl.csv  ($n columns)
-- ---------------------------------------------------------------------------
PROMPT ******  Loading $tbl from $tbl.csv ....

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE ${tbl}_ext';
EXCEPTION
   WHEN OTHERS THEN NULL;   -- first run: nothing to drop
END;
/

CREATE TABLE ${tbl}_ext (
$ext_defs
)
ORGANIZATION EXTERNAL (
   TYPE ORACLE_LOADER
   DEFAULT DIRECTORY sh_csv_dir
   ACCESS PARAMETERS (
      RECORDS DELIMITED BY NEWLINE
      CHARACTERSET AL32UTF8
      SKIP 1
      NOBADFILE
      NOLOGFILE
      NODISCARDFILE
      FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LRTRIM
      MISSING FIELD VALUES ARE NULL
      REJECT ROWS WITH ALL NULL FIELDS
      (
$fld_list
      )
   )
   LOCATION ('$tbl.csv')
)
REJECT LIMIT UNLIMITED
NOPARALLEL;

INSERT /*+ APPEND */ INTO $tbl (
$ins_list
)
SELECT
$ins_list
FROM ${tbl}_ext;

COMMIT;

DROP TABLE ${tbl}_ext;
EOF
done

cat <<'FTR'

PROMPT ******  CSV load complete.
FTR
} > "$OUT"

echo "Wrote $OUT ($(wc -l < "$OUT") lines)"
