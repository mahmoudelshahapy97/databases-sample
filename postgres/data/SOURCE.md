# PostgreSQL seed data — provenance

Vendored copies of the upstream files the loaders in `postgres/init/` read.
Mounted read-only at `/source` inside the `db_postgres` container.
Nothing here is edited: every dialect fix is applied on the fly by the loaders.

| Folder | Files | Upstream | License |
|--------|-------|----------|---------|
| `chinook/` | `Chinook_PostgreSql.sql` (from `ChinookDatabase/DataSources/`) | [lerocha/chinook-database](https://github.com/lerocha/chinook-database) | MIT — `LICENSE.md` alongside |
| `pagila/` | `pagila-schema.sql`, `pagila-data.sql` | [devrimgunduz/pagila](https://github.com/devrimgunduz/pagila) | MIT-style — `LICENSE.txt` alongside |
| `employees/` | `employees.sql`, `objects.sql` (from `postgresql/`), `load_*.dump` (8 files, from repo root) | [datacharmer/test_db](https://github.com/datacharmer/test_db) | CC BY-SA 3.0 Unported |
| `northwind/` | `northwind.sql` (from `pgsql/`) | [harryho/db-samples](https://github.com/harryho/db-samples) | no license file shipped upstream |
| `ecommerce/` | `ecommerce.sql` (from `pgsql/`) | [harryho/db-samples](https://github.com/harryho/db-samples) | no license file shipped upstream |
| `world/` | `world.sql` (MySQL 8 dump) | MySQL `world` sample database (Oracle) | — |

Hand-written PostgreSQL DDL lives in `postgres/assets/` (mounted at `/seed`), not here:
`world_pg.sql` is the PostgreSQL port of the world schema, since only the `INSERT`
lines of the MySQL dump above are reused.
