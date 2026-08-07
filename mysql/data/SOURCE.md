# MySQL seed data — provenance

Vendored copies of the upstream files the loaders in `mysql/init/` read.
Mounted read-only at `/source` inside the `db_mysql` container.

| Folder | Files | Upstream | License |
|--------|-------|----------|---------|
| `chinook/` | `Chinook_MySql.sql` (from `ChinookDatabase/DataSources/`) | [lerocha/chinook-database](https://github.com/lerocha/chinook-database) | MIT — `LICENSE.md` alongside |
| `sakila/` | `sakila-schema.sql`, `sakila-data.sql` | MySQL Sakila sample database v0.8 (MySQL AB / Oracle), via [ivanceras/sakila](https://github.com/ivanceras/sakila) | BSD 3-clause — notice at the top of both files |
| `northwind/` | `northwind.sql` (from `mysql/`) | [harryho/db-samples](https://github.com/harryho/db-samples) | no license file shipped upstream |
| `world/` | `world.sql` | MySQL `world` sample database (Oracle) — same file the postgres service converts | — |
| `menagerie/` | `cr_pet_tbl.sql`, `cr_event_tbl.sql`, `load_pet_tbl.sql`, `ins_puff_rec.sql`, `pet.txt`, `event.txt`, `README.txt` | MySQL `menagerie` tutorial database (Oracle) | — |

Two files are deliberately not used as shipped:

- `menagerie/load_pet_tbl.sql` uses `LOAD DATA LOCAL INFILE`, which needs
  `local_infile` enabled on client *and* server. `05_menagerie.sh` converts
  `pet.txt` / `event.txt` into `INSERT` statements instead.
- `chinook/Chinook_MySql.sql` creates the database as `Chinook`; the loader
  lower-cases it to `chinook` (database names are case-sensitive on Linux) so it
  matches the naming used by the other four datasets and the other engines.

Everything else runs exactly as upstream ships it.
