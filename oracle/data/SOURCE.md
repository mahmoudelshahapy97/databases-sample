# Oracle seed data — provenance

Vendored copies of the upstream files the loaders in `oracle/init/` read.
Mounted read-only at `/source` inside the `db_oracle` container.
Nothing here is edited: SQL*Plus/SQLcl fixes are applied on the fly by the loaders.

| Folder | Files | Upstream | License |
|--------|-------|----------|---------|
| `chinook/` | `Chinook_Oracle.sql` (from `ChinookDatabase/DataSources/`) | [lerocha/chinook-database](https://github.com/lerocha/chinook-database) | MIT — `LICENSE.md` alongside |
| `human_resources/` | `hr_create.sql`, `hr_populate.sql` | [oracle-samples/db-sample-schemas](https://github.com/oracle-samples/db-sample-schemas) | UPL 1.0 — `LICENSE.txt` alongside |
| `customer_orders/` | `co_create.sql`, `co_populate.sql` | same | same |
| `sales_history/` | `sh_create.sql`, `sh_populate.sql`, + `costs`, `customers`, `promotions`, `sales`, `supplementary_demographics`, `times` `.csv` | same | same |

`chinook/Chinook_Oracle.sql` is not loaded directly at runtime — `01_chinook.sh` runs
the pre-converted `oracle/assets/chinook_oracle_fixed.sql` (baked into the image at
`/opt/seed`) and only falls back to this file. It is kept because it is the input to
`oracle/tools/fix_chinook_oracle.py`, which regenerates that asset.

The six CSVs are read by Oracle external tables through the `SH_CSV_DIR` directory
object, which `04_sh.sh` points at `/source/sales_history`. `oracle/assets/sh_load_csv.sql`
is generated from their header lines by `oracle/tools/gen_sh_load_csv.sh`.
