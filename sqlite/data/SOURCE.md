# SQLite seed data — provenance

Vendored copies of the upstream files `sqlite/entrypoint.sh` reads.
Mounted read-only at `/source` inside the `db_sqlite` container.

| Folder | Files | Upstream | License |
|--------|-------|----------|---------|
| `chinook/` | `Chinook_Sqlite.sql` (from `ChinookDatabase/DataSources/`) | [lerocha/chinook-database](https://github.com/lerocha/chinook-database) | MIT — `LICENSE.md` alongside |
| `northwind/` | `northwind_core.sql` (from `sqlite/`) | [harryho/db-samples](https://github.com/harryho/db-samples) | no license file shipped upstream |
| `menagerie/` | the full MySQL menagerie tutorial set: `cr_pet_tbl.sql`, `cr_event_tbl.sql`, `load_pet_tbl.sql`, `ins_puff_rec.sql`, `pet.txt`, `event.txt`, `README.txt` | MySQL `menagerie` tutorial database (Oracle) | — |

`menagerie/` is reference only — no loader reads it. Its MySQL `#` comments and
`LOAD DATA INFILE` statements do not work in SQLite, so it was hand-converted into
`sqlite/init/menagerie_sqlite.sql`, which is baked into the image and is what actually
builds `menagerie.db`. These files are the provenance for that conversion.
