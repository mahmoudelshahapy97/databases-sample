# SQL Server seed data — provenance

Vendored copies of the upstream files `sqlserver/entrypoint.sh` reads.
Mounted read-only at `/source` inside the `db_sqlserver` container.
Nothing here is edited: the `dbo` → named-schema rewrites happen on the fly.

| Folder | Files | Upstream | License |
|--------|-------|----------|---------|
| `chinook/` | `Chinook_SqlServer.sql` (from `ChinookDatabase/DataSources/`) | [lerocha/chinook-database](https://github.com/lerocha/chinook-database) | MIT — `LICENSE.md` alongside |
| `northwind/` | `northwind.sql` (from `mssql/`) | [harryho/db-samples](https://github.com/harryho/db-samples) | no license file shipped upstream |
