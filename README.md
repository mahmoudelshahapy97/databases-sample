# Multi-Database Docker Compose

A single `docker compose up -d` that spins up **5 database engines**, each pre-loaded
with real-world sample schemas that live in this repo — every engine folder carries its
own SQL and data. No downloading required.

Two things hold across every engine:

* **Every dataset gets its own database *and* its own named schema.** Nothing is left
  sitting in `public` or `dbo`.
* **Every dataset gets its data**, not just its DDL — including the 3.9 M-row
  `employees` dataset and the 1.06 M-row Oracle `SH` schema, both of which are loaded
  during container init.

---

## Quick Start

```bash
# 1. Review secrets (already pre-configured for local dev)
cat .env

# 2. Start everything
docker compose up -d

# 3. Watch the seeding go by
docker compose logs -f postgres oracle

# 4. Check all services are healthy
docker compose ps

# 5. Prove the data actually landed, in the right schemas
./verify.sh

# 6. Tear down (keeps data volumes)
docker compose down

# 7. Tear down + wipe all data
docker compose down -v
```

> **Individual engines** — start only what you need:
> ```bash
> docker compose up -d postgres
> docker compose up -d mysql
> docker compose up -d sqlserver
> docker compose up -d oracle
> docker compose up -d sqlite
> ```

### First-start time

Seeding runs once, inside container init, and the result is kept in a named volume.
Budget accordingly:

| Engine | First start | Later starts | Why |
|--------|-------------|--------------|-----|
| SQLite | ~10 s | instant | Tiny files |
| MySQL | ~1 min | ~5 s | 5 datasets, ~85 000 rows total |
| PostgreSQL | **3–6 min** | ~2 s | 3.9 M `employees` rows (~170 MB of INSERTs) |
| SQL Server | ~2 min | ~30 s | Engine startup dominates |
| Oracle XE | **15–25 min** | ~1 min | CDB/PDB creation, then the 1.06 M-row `SH` schema |

Oracle is the long pole, and `SH` is most of it. To skip just that schema:

```bash
# in .env
ORACLE_SKIP_SH=true
```

`CHINOOK`, `HR` and `CO` are unaffected either way. If `SH` fails for any reason it
prints a diagnostic banner and container init continues — the other three schemas
stay usable.

---

## Database and Schema Names by Engine

| Engine | Database | Schema | Notes |
|--------|----------|--------|-------|
| 🐘 **PostgreSQL** | `chinook` | `chinook` | |
| | `pagila` | `pagila` | |
| | `employees` | `employees` | |
| | `northwind` | `northwind` | |
| | `ecommerce` | `ecommerce` | |
| | `world` | `world` | |
| 🐬 **MySQL** | `chinook` | — | A database *is* the schema in MySQL |
| | `sakila` | — | |
| | `northwind` | — | |
| | `world` | — | |
| | `menagerie` | — | |
| 🪟 **SQL Server** | `Chinook` | `chinook` | |
| | `Northwind` | `northwind` | |
| 🔴 **Oracle XE** | `XEPDB1` | `CHINOOK` | In Oracle a user *is* a schema |
| | `XEPDB1` | `HR` | |
| | `XEPDB1` | `CO` | |
| | `XEPDB1` | `SH` | |
| 📦 **SQLite** | `chinook.db` | — | A file *is* the namespace |
| | `menagerie.db` | — | |
| | `northwind.db` | — | |

Each PostgreSQL database has `search_path` set at the database level
(`ALTER DATABASE chinook SET search_path TO chinook, public`), so queries never need
to qualify anything — `SELECT * FROM album` just works after connecting to `chinook`.

---

## Databases at a Glance

### 🐘 PostgreSQL 16 — port `5432`

| Database.schema | Domain | Tables | Rows | Source |
|-----------------|--------|--------|------|--------|
| `chinook.chinook` | Digital music store | 11 | ~15 600 | `postgres/data/chinook/` |
| `pagila.pagila` | DVD rental store | 15 + views | ~15 000 | `postgres/data/pagila/` |
| `employees.employees` | HR / payroll | 6 + views | **~3 919 000** | `postgres/data/employees/` |
| `northwind.northwind` | Classic ERP | 13 | ~2 500 | `postgres/data/northwind/` |
| `ecommerce.ecommerce` | Modern e-commerce | ~10 | ~4 000 | `postgres/data/ecommerce/` |
| `world.world` | World geography | 3 | 5 302 | `postgres/data/world/` |

`employees` breaks down as: `departments` 9, `dept_manager` 24, `employees` 300 024,
`dept_emp` 331 603, `titles` 443 308, `salaries` 2 844 047.

### 🐬 MySQL 8.4 — port `3306`

| Database | Domain | Tables | Rows | Source |
|----------|--------|--------|------|--------|
| `chinook` | Digital music store | 11 | ~15 600 | `mysql/data/chinook/` |
| `sakila` | DVD rental store | 16 + views + routines | ~46 000 | `mysql/data/sakila/` |
| `northwind` | Classic ERP | 13 | ~3 300 | `mysql/data/northwind/` |
| `world` | World geography | 3 | 5 302 | `mysql/data/world/` |
| `menagerie` | Pet tutorial | 2 | 19 | `mysql/data/menagerie/` |

MySQL has no second namespace level — a database *is* a schema — so one database per
dataset is the exact equivalent of the named schemas used on PostgreSQL and SQL Server.

`sakila` is MySQL's own sample database and the original that PostgreSQL's `pagila`
was ported from: the same 15-table rental model on two engines, which makes it the
natural cross-engine comparison here. `world` is loaded from the *same file* the
postgres service uses — natively on MySQL (it is a `mysqldump`), converted on
PostgreSQL.

### 🪟 SQL Server 2022 Developer — port `1433`

| Database.schema | Domain | Tables | Rows | Source |
|-----------------|--------|--------|------|--------|
| `Chinook.chinook` | Digital music store | 11 | ~15 600 | `sqlserver/data/chinook/` |
| `Northwind.northwind` | Classic ERP | 13 + views + procs | ~3 300 | `sqlserver/data/northwind/` |

### 🔴 Oracle XE 21c — port `1521` — PDB: `XEPDB1`

| Schema | Domain | Tables | Rows | Source |
|--------|--------|--------|------|--------|
| `CHINOOK` | Digital music store | 11 | ~15 600 | `oracle/data/chinook/` |
| `HR` | Human resources | 7 | ~220 | `oracle/data/human_resources/` |
| `CO` | Customer orders (JSON-heavy) | 7 + 4 views | 8 783 | `oracle/data/customer_orders/` |
| `SH` | Sales history (data warehouse) | 8 + 2 MVs + 5 dimensions | **1 063 396** | `oracle/data/sales_history/` |

`SH` is the interesting one for query work: range-partitioned `sales` (918 843 rows)
and `costs` (82 112), bitmap indexes, materialized views with query rewrite, and
OLAP dimension hierarchies.

### 📦 SQLite via Datasette — `http://localhost:8001`

| File | Domain | Tables | Rows | Source |
|------|--------|--------|------|--------|
| `chinook.db` | Digital music store | 11 | ~15 600 | `sqlite/data/chinook/` |
| `menagerie.db` | Pet tutorial | 2 | 19 | `sqlite/init/menagerie_sqlite.sql` |
| `northwind.db` | Classic ERP | 13 | ~3 300 | `sqlite/data/northwind/` |

---

## Connecting

All credentials are development-only and come from `.env`. Change them there if you
need to; the values below are the defaults.

### Credentials at a glance

| Engine | From the host | From another container | Port | User | Password |
|--------|---------------|------------------------|------|------|----------|
| PostgreSQL | `localhost` | `db_postgres` | `5432` | `postgres` | `postgres123` |
| MySQL | `localhost` | `db_mysql` | `3306` | `root` | `mysql123` |
| SQL Server | `localhost` | `db_sqlserver` | `1433` | `sa` | `SqlServer123!` |
| Oracle XE | `localhost` | `db_oracle` | `1521` | per schema (below) | `Oracle123!` |
| SQLite | `localhost` | `db_sqlite` | `8001` | — | — |

Containers reach each other by service hostname on the `multidb_network` network.
Everything is plain TCP — **disable SSL/TLS** in whatever client you use.

> **No local client installed?** Every example below has a `docker exec` variant that
> uses the client already inside the container, so you need nothing on your machine.

---

### 🐘 PostgreSQL — 6 databases

The schema name always matches the database name, and `search_path` is already set at
the database level, so **unqualified table names just work**.

| Database | Schema | Connect from host | Connect via Docker |
|----------|--------|-------------------|--------------------|
| `chinook` | `chinook` | `psql -h localhost -U postgres -d chinook` | `docker exec -it db_postgres psql -U postgres -d chinook` |
| `pagila` | `pagila` | `psql -h localhost -U postgres -d pagila` | `docker exec -it db_postgres psql -U postgres -d pagila` |
| `employees` | `employees` | `psql -h localhost -U postgres -d employees` | `docker exec -it db_postgres psql -U postgres -d employees` |
| `northwind` | `northwind` | `psql -h localhost -U postgres -d northwind` | `docker exec -it db_postgres psql -U postgres -d northwind` |
| `ecommerce` | `ecommerce` | `psql -h localhost -U postgres -d ecommerce` | `docker exec -it db_postgres psql -U postgres -d ecommerce` |
| `world` | `world` | `psql -h localhost -U postgres -d world` | `docker exec -it db_postgres psql -U postgres -d world` |

`psql` will prompt for the password; set `PGPASSWORD=postgres123` to skip that.

```bash
# Prove the schema wiring is live
docker exec -it db_postgres psql -U postgres -d chinook -c 'SHOW search_path;'
#  search_path
# ------------------
#  chinook, public

# Unqualified, no schema prefix needed
docker exec -it db_postgres psql -U postgres -d chinook -c 'SELECT COUNT(*) FROM track;'
```

> **Naming note:** the PostgreSQL port of Chinook uses lowercase, unquoted names
> (`album`, `track`, `invoice_line`), unlike the SQL Server and SQLite ports which use
> `[Album]`, `[Track]`, `[InvoiceLine]`. `SELECT * FROM "Track"` fails on PostgreSQL;
> `SELECT * FROM track` is correct.

Useful once connected:

```
\l                 -- list all 6 databases
\dn                -- list schemas in this database
\dt                -- list tables in search_path (i.e. the named schema)
\dt chinook.*      -- list tables with an explicit schema
\d track           -- describe a table
```

**Connection URLs**

```
psql / libpq      postgresql://postgres:postgres123@localhost:5432/chinook
SQLAlchemy        postgresql+psycopg://postgres:postgres123@localhost:5432/chinook
JDBC              jdbc:postgresql://localhost:5432/chinook?currentSchema=chinook
```

To pin the schema explicitly from an app rather than relying on the database default:

```python
create_engine(
    "postgresql+psycopg://postgres:postgres123@localhost:5432/chinook",
    connect_args={"options": "-csearch_path=chinook"},
)
```

---

### 🐬 MySQL — 5 databases

There is no schema level to worry about: `USE <database>` and every unqualified name
resolves inside it.

| Database | Connect from host | Connect via Docker |
|----------|-------------------|--------------------|
| `chinook` | `mysql -h 127.0.0.1 -P 3306 -u root -p chinook` | `docker exec -it db_mysql mysql -u root -p chinook` |
| `sakila` | `mysql -h 127.0.0.1 -P 3306 -u root -p sakila` | `docker exec -it db_mysql mysql -u root -p sakila` |
| `northwind` | `mysql -h 127.0.0.1 -P 3306 -u root -p northwind` | `docker exec -it db_mysql mysql -u root -p northwind` |
| `world` | `mysql -h 127.0.0.1 -P 3306 -u root -p world` | `docker exec -it db_mysql mysql -u root -p world` |
| `menagerie` | `mysql -h 127.0.0.1 -P 3306 -u root -p menagerie` | `docker exec -it db_mysql mysql -u root -p menagerie` |

Use `-h 127.0.0.1`, not `-h localhost`: the MySQL client treats `localhost` as "connect
over a unix socket", which on the host is not where this server is.

```bash
# Password on the command line without the client's warning
docker exec -it -e MYSQL_PWD=mysql123 db_mysql \
  mysql -u root -e "SELECT COUNT(*) FROM sakila.film;"
```

> **Naming note:** the MySQL port of Chinook keeps upper-camel table names
> (`Album`, `Track`, `InvoiceLine`), like the SQL Server and SQLite ports and unlike
> PostgreSQL's lower-case port. On Linux, MySQL table names are case-sensitive by
> default, so `SELECT * FROM track` fails where `SELECT * FROM Track` works. Database
> names are lower-case on every engine here, Chinook's upstream `Chinook` included —
> `01_chinook.sh` rewrites it.

Useful once connected:

```
SHOW DATABASES;              -- all 5 datasets
SHOW TABLES;                 -- tables in the current database
DESCRIBE Track;              -- describe a table
SHOW CREATE TABLE Track\G    -- full DDL
```

**Connection URLs**

```
mysql CLI         mysql://root:mysql123@127.0.0.1:3306/chinook
SQLAlchemy        mysql+pymysql://root:mysql123@127.0.0.1:3306/chinook
JDBC              jdbc:mysql://localhost:3306/chinook?useSSL=false&allowPublicKeyRetrieval=true
```

---

### 🪟 SQL Server — 2 databases

| Database | Schema | Connect from host | Connect via Docker |
|----------|--------|-------------------|--------------------|
| `Chinook` | `chinook` | `sqlcmd -S localhost,1433 -U sa -P 'SqlServer123!' -No -d Chinook` | `docker exec -it db_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'SqlServer123!' -No -d Chinook` |
| `Northwind` | `northwind` | `sqlcmd -S localhost,1433 -U sa -P 'SqlServer123!' -No -d Northwind` | `docker exec -it db_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'SqlServer123!' -No -d Northwind` |

`-No` makes encryption optional — `mssql-tools18` requires TLS by default and would
otherwise reject this server's self-signed certificate.

```bash
docker exec -it db_sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'SqlServer123!' -No -d Chinook \
  -Q "SELECT COUNT(*) FROM chinook.Track"
```

**⚠ Qualify your table names here.** `sa` is permanently mapped to the `dbo` user in
every database and `dbo`'s default schema cannot be changed, so `SELECT * FROM Track`
fails while `SELECT * FROM chinook.Track` works.

If you need unqualified names to resolve — worth doing if an LLM is generating the SQL
— create your own login with the right default schema (dev only):

```sql
-- run once as sa, against the master database
CREATE LOGIN app WITH PASSWORD = 'App_Pass123!', CHECK_POLICY = OFF;
GO
USE Chinook;
CREATE USER app FOR LOGIN app WITH DEFAULT_SCHEMA = [chinook];
ALTER ROLE db_datareader ADD MEMBER app;
GO
USE Northwind;
CREATE USER app FOR LOGIN app WITH DEFAULT_SCHEMA = [northwind];
ALTER ROLE db_datareader ADD MEMBER app;
GO
```

Then `SELECT * FROM Track` works when connected as `app`.

Useful once connected:

```sql
SELECT name FROM sys.databases;                       -- list databases
SELECT name FROM sys.schemas WHERE schema_id > 4;     -- list non-built-in schemas
SELECT s.name AS [schema], t.name AS [table]
  FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id
 ORDER BY 1, 2;
```

**Connection URLs** — the `!` in the password must be percent-encoded as `%21`
inside URLs.

```
SQLAlchemy (pyodbc)  mssql+pyodbc://sa:SqlServer123%21@localhost:1433/Chinook?driver=ODBC+Driver+18+for+SQL+Server&Encrypt=no&TrustServerCertificate=yes
SQLAlchemy (pymssql) mssql+pymssql://sa:SqlServer123%21@localhost:1433/Chinook
JDBC                 jdbc:sqlserver://localhost:1433;databaseName=Chinook;encrypt=false;trustServerCertificate=true
ADO.NET              Server=localhost,1433;Database=Chinook;User Id=sa;Password=SqlServer123!;Encrypt=False;TrustServerCertificate=True
```

---

### 🔴 Oracle XE — 4 schemas in one PDB

There is a single database here (`XEPDB1`); the four datasets are separate **users**,
which in Oracle *are* schemas. Connect as the owner and unqualified names resolve to
that schema automatically.

| Schema | User / password | Connect from host | Connect via Docker |
|--------|-----------------|-------------------|--------------------|
| `CHINOOK` | `chinook` / `Oracle123!` | `sqlplus 'chinook/Oracle123!@//localhost:1521/XEPDB1'` | `docker exec -it db_oracle sqlplus 'chinook/Oracle123!@//localhost/XEPDB1'` |
| `HR` | `hr` / `Oracle123!` | `sqlplus 'hr/Oracle123!@//localhost:1521/XEPDB1'` | `docker exec -it db_oracle sqlplus 'hr/Oracle123!@//localhost/XEPDB1'` |
| `CO` | `co` / `Oracle123!` | `sqlplus 'co/Oracle123!@//localhost:1521/XEPDB1'` | `docker exec -it db_oracle sqlplus 'co/Oracle123!@//localhost/XEPDB1'` |
| `SH` | `sh` / `Oracle123!` | `sqlplus 'sh/Oracle123!@//localhost:1521/XEPDB1'` | `docker exec -it db_oracle sqlplus 'sh/Oracle123!@//localhost/XEPDB1'` |
| *(DBA)* | `system` / `Oracle123!` | `sqlplus 'system/Oracle123!@//localhost:1521/XEPDB1'` | `docker exec -it db_oracle sqlplus 'system/Oracle123!@//localhost/XEPDB1'` |

Single-quote the whole connect string — `!` and `@` are shell metacharacters in both
bash and PowerShell.

```bash
docker exec -it db_oracle sqlplus -s 'sh/Oracle123!@//localhost/XEPDB1' <<'SQL'
SELECT COUNT(*) FROM sales;
EXIT;
SQL
```

**Reading across schemas.** Each user only sees its own tables by default. To query
another schema, either qualify (`SELECT * FROM sh.sales`) with a grant in place, or
switch the session's default schema:

```sql
ALTER SESSION SET CURRENT_SCHEMA = SH;   -- now unqualified names hit SH
```

For one read-only login that can reach all four schemas — convenient for a text-to-SQL
harness, and far too broad for anything but a sandbox:

```sql
-- as system
CREATE USER app IDENTIFIED BY "App_Pass123";
GRANT CREATE SESSION, SELECT ANY TABLE TO app;
```

Useful once connected:

```sql
SELECT table_name FROM user_tables ORDER BY 1;            -- my own tables
SELECT owner, table_name FROM all_tables                  -- everything I can see
 WHERE owner IN ('CHINOOK','HR','CO','SH') ORDER BY 1, 2;
SELECT username FROM all_users ORDER BY 1;                -- all schemas
SHOW USER                                                 -- who am I
```

**Connection URLs**

```
Easy Connect      //localhost:1521/XEPDB1
SQLAlchemy        oracle+oracledb://sh:Oracle123%21@localhost:1521/?service_name=XEPDB1
python-oracledb   oracledb.connect(user="sh", password="Oracle123!", dsn="localhost:1521/XEPDB1")
JDBC              jdbc:oracle:thin:@//localhost:1521/XEPDB1
```

---

### 📦 SQLite — 3 files via Datasette

Each dataset is its own `.db` file inside the container's `sqlite_data` volume. There
is no user, password, or schema.

| File | Datasette page | Direct CLI |
|------|----------------|-----------|
| `chinook.db` | http://localhost:8001/chinook | `docker exec -it db_sqlite sqlite3 /data/chinook.db` |
| `menagerie.db` | http://localhost:8001/menagerie | `docker exec -it db_sqlite sqlite3 /data/menagerie.db` |
| `northwind.db` | http://localhost:8001/northwind | `docker exec -it db_sqlite sqlite3 /data/northwind.db` |

Browse and run ad-hoc SQL at **http://localhost:8001**.

**HTTP/JSON API** — Datasette exposes read-only SQL over HTTP, which is often the
easiest way to reach SQLite from application code:

```bash
# Arbitrary SQL, results as a JSON array
curl -G 'http://localhost:8001/chinook.json' \
     --data-urlencode 'sql=SELECT Title FROM Album LIMIT 3' \
     --data-urlencode '_shape=array'

# A whole table
curl 'http://localhost:8001/chinook/Album.json?_size=3'

# What databases and tables exist
curl 'http://localhost:8001/-/databases.json'
```

**Want the file locally instead?** Copy it out and point any SQLite client at it:

```bash
docker cp db_sqlite:/data/chinook.db ./chinook.db
sqlite3 ./chinook.db '.tables'
```

```
SQLAlchemy   sqlite:///./chinook.db          (after docker cp)
```

Useful once connected with `sqlite3`:

```
.databases
.tables
.schema Album
```

---

### From another container

Use the service hostname instead of `localhost`, and join the network:

```yaml
services:
  my-app:
    networks: [db_network]
    environment:
      PG_URL:     postgresql://postgres:postgres123@db_postgres:5432/chinook
      MYSQL_URL:  mysql+pymysql://root:mysql123@db_mysql:3306/chinook
      MSSQL_HOST: db_sqlserver
      ORACLE_DSN: db_oracle:1521/XEPDB1
      SQLITE_API: http://db_sqlite:8001
networks:
  db_network:
    external: true
    name: multidb_network
```

Or attach an existing container: `docker network connect multidb_network my-app`.

### GUI clients (DBeaver, DataGrip, pgAdmin, Azure Data Studio)

Use the host/port/user/password from the table above and **turn SSL off**. Per engine:

| Client setting | PostgreSQL | MySQL | SQL Server | Oracle | SQLite |
|----------------|-----------|-------|-----------|--------|--------|
| Host / Port | `localhost` / `5432` | `127.0.0.1` / `3306` | `localhost` / `1433` | `localhost` / `1521` | n/a — open the copied file |
| Database | `chinook` (one entry per DB) | any of the 5 (all visible from one entry) | `Chinook` / `Northwind` | Service name `XEPDB1` | — |
| User | `postgres` | `root` | `sa` | `chinook` / `hr` / `co` / `sh` | — |
| SSL / Encrypt | Disable | Disable | Disable + Trust server certificate | Disable | — |

PostgreSQL and SQL Server need one connection entry per database; Oracle needs one per
schema user. MySQL shows all five databases from a single entry. In DBeaver, tick
**Show all databases** to see all six PostgreSQL databases from a single entry.

---

## Verifying a Seed

`./verify.sh` connects to every running engine and reports exact `COUNT(*)` totals
per schema — not planner estimates, so an empty-but-created table shows as `0` rather
than hiding behind missing statistics. It also asserts the things that are easy to get
silently wrong:

* no tables left behind in PostgreSQL `public` or SQL Server `dbo`
* nothing stray in the default `postgres` database
* all five MySQL databases populated, and no capital-`C` `Chinook` left over from
  the upstream script the loader lower-cases
* all four Oracle schemas present
* all three SQLite files built
* the temporary SQL Server seeding login cleaned up

```bash
./verify.sh              # every engine
./verify.sh oracle       # one engine
                         # (postgres | mysql | sqlserver | oracle | sqlite)
```

Exit status is `0` on success, `1` if anything was reachable but wrong — usable in CI.

---

## Repository Layout

Each engine folder carries everything it seeds — scripts *and* data. There are no
shared source folders.

```
postgres/
  init/     00_create_dbs.sh … 06_world.sh   → /docker-entrypoint-initdb.d
  assets/   world_pg.sql                     → /seed          (@-called by 06_)
  data/     chinook/ pagila/ employees/      → /source        (vendored upstream)
            northwind/ ecommerce/ world/
            SOURCE.md                        (provenance + licenses)
mysql/
  init/     01_chinook.sh … 05_menagerie.sh  → /docker-entrypoint-initdb.d
  assets/   lib.sh                           → /seed          (sourced by init)
  data/     chinook/ sakila/ northwind/      → /source
            world/ menagerie/ SOURCE.md
sqlserver/
  Dockerfile, entrypoint.sh
  data/     chinook/ northwind/ SOURCE.md    → /source
oracle/
  init/     01_chinook.sh … 06_healthcare.sh → /opt/seed/init  (driven by
                                             entrypoint.sh, NOT the gvenzl hook)
  assets/   chinook_oracle_fixed.sql         → /opt/seed      (@-called by init)
            sh_load_csv.sql
  data/     chinook/ human_resources/        → /source
            customer_orders/ sales_history/  (SH: 6 CSVs read via SH_CSV_DIR)
            SOURCE.md
  tools/    fix_chinook_oracle.py            (host-side, not shipped)
            gen_sh_load_csv.sh
sqlite/
  Dockerfile, entrypoint.sh, init/menagerie_sqlite.sql
  data/     chinook/ northwind/              → /source
            menagerie/ SOURCE.md             (menagerie is reference only)
verify.sh
```

> **`assets/` vs `data/`.** `data/` is vendored upstream SQL/CSV, used exactly as
> shipped — every dialect fix is applied on the fly at load time, so these files are
> never edited. `assets/` is ours: `world_pg.sql` (hand-written), `lib.sh` (the MySQL
> loaders' shared socket-discovery + client wrapper), plus `chinook_oracle_fixed.sql`
> and `sh_load_csv.sql`, both generated from `data/` by the scripts in `oracle/tools/`.

> **Why `assets/` exists.** The Postgres, MySQL and Oracle entrypoints all execute
> *every* `.sh` **and `.sql`** file they find in their init directory. SQL that is meant to be
> `@`-called by a loader script must therefore live outside that directory, or it also
> runs standalone — which previously dropped `world`'s tables into the default
> `postgres` database and Chinook's tables into Oracle's `SYSTEM` schema. `verify.sh`
> checks for exactly that regression.

---

## How Init Scripts Work

| Engine | Mechanism | Runs When |
|--------|-----------|-----------|
| PostgreSQL | Scripts in `/docker-entrypoint-initdb.d/` (alphabetical) | Once, on first container start. `99_done.sh` writes `PGDATA/.seed_complete`; the healthcheck requires it, so a partial seed reports UNHEALTHY instead of serving incomplete data |
| MySQL | Scripts in `/docker-entrypoint-initdb.d/` (alphabetical), against a temporary socket-only server | Once, on first container start |
| SQL Server | Custom entrypoint: polls readiness → runs `sqlcmd` | Each start, skips datasets with a marker under `/var/opt/mssql/data/.seeded/` |
| Oracle | Custom entrypoint: polls XEPDB1 → runs `/opt/seed/init/*.sh` | Each start, skips schemas with a marker under `/opt/oracle/oradata/.seeded/` |
| SQLite | Custom entrypoint: `sqlite3 db.db < script.sql` | Each start, skips if `.db` exists |

> **Re-seeding**: remove the named volume to force re-initialization:
> ```bash
> docker compose down
> docker volume rm multidb_postgres_data    # or whichever engine
> docker compose up -d postgres
> ```

---

## Source → Container File Mapping

Every engine folder is self-contained: the SQL, CSV and dump files its loaders read
live under `<engine>/data/` and are bind-mounted read-only at `/source`. Provenance
(upstream repo + license per dataset) is recorded in each `<engine>/data/SOURCE.md`.

| Host folder | Mounted at | Contents |
|-------------|-----------|----------|
| `postgres/data/` | `/source/` | `chinook/`, `pagila/`, `employees/`, `northwind/`, `ecommerce/`, `world/` |
| `mysql/data/` | `/source/` | `chinook/`, `sakila/`, `northwind/`, `world/`, `menagerie/` |
| `sqlserver/data/` | `/source/` | `chinook/`, `northwind/` |
| `oracle/data/` | `/source/` | `chinook/`, `human_resources/`, `customer_orders/`, `sales_history/` (+ 6 CSVs) |
| `sqlite/data/` | `/source/` | `chinook/`, `northwind/`, `menagerie/` (reference only) |

Three folders hold *our* files rather than vendored upstream ones, and are mounted
separately: `postgres/assets/` → `/seed` (hand-written `world_pg.sql`),
`mysql/assets/` → `/seed` (`lib.sh`, sourced by the loaders) and `oracle/assets/`
→ `/opt/seed`, baked into the image (`chinook_oracle_fixed.sql`, `sh_load_csv.sql`).

---

## Adjustments Applied Automatically

### Schema relocation

| Engine | Approach |
|--------|----------|
| PostgreSQL | `SET search_path` per loader. Sources are unqualified, so objects land in the named schema. Exception: **pagila** is a `pg_dump` output that qualifies all 600 references as `public.<name>` — those are rewritten to `pagila.`, along with the dump's own `set_config('search_path', …)`. |
| SQL Server | **Chinook** is fully `[dbo]`-qualified → rewritten to `[chinook]`, with a `CREATE SCHEMA` batch spliced in after `USE [Chinook]`. **Northwind** is mixed: 5 tables are `dbo`-qualified but 8 are created unqualified, and `sa` is permanently mapped to `dbo`. So it is loaded as a throwaway login whose `DEFAULT_SCHEMA` is `[northwind]`, with all `dbo` references rewritten; the login is dropped afterwards. |
| Oracle | Nothing to do — a user *is* a schema, so `CHINOOK`/`HR`/`CO`/`SH` are separate namespaces by construction. |
| SQLite | Nothing to do — one `.db` file per dataset is the equivalent isolation. |

### SQL dialect fixes

| File | Issue | Fix |
|------|-------|-----|
| `Chinook_PostgreSql.sql` | `N'string'` T-SQL prefix | `sed` strips `N'` → `'` |
| `Chinook_PostgreSql.sql` | `CREATE DATABASE` / `\connect` | Removed; DB pre-created by `00_` |
| `pagila-schema.sql` | `uuidv7()`, `VIRTUAL`, `public.vector(20)`, `USING hnsw` | Rewritten for PG 16 without pgvector |
| `northwind/northwind.sql` (pg) | `N'string'`; `owner = hho` hardcoded | `sed` strips both |
| `world/world.sql` | Full MySQL dump | Schema hand-written (`world_pg.sql`); only `INSERT` lines extracted, backticks stripped, `\'` → `''` |
| `employees/load_*.dump` | MySQL backtick quoting | `sed 's/`//g'`, then loaded parents-first |
| `Chinook_Oracle.sql` | `GRANT` / `CONNECT` lines; no multi-row `VALUES` | Pre-converted to `INSERT ALL … SELECT 1 FROM DUAL` batches |
| `hr_create.sql`, `hr_populate.sql` | SQL\*Plus directives | Stripped before running |
| `co_create.sql`, `co_populate.sql` | — | Run **unmodified**: their `SET DEFINE OFF` is load-bearing (one address contains `&`) |
| `sh_populate.sql` | `LOAD <table> <file>.csv` is a **SQLcl** command, absent from the image | Six `LOAD` lines rewritten into one `@sh_load_csv.sql`, which loads the same CSVs via external tables |
| `sh_populate.sql` | `INDEXTYPE IS ctxsys.context` needs Oracle Text, stripped from `-slim` images | Statement removed, then retried only if `CTXSYS` exists |
| `sqlite/data/menagerie/` | MySQL `#` comments; `LOAD DATA INFILE` | Rewritten by hand as `sqlite/init/menagerie_sqlite.sql`, which is what builds `menagerie.db` |

### Bulk-load tuning

`employees` uses `synchronous_commit = off` and `session_replication_role = replica`
for the duration of the load — standard bulk-load practice that skips per-row FK
trigger validation. The dumps are a consistent snapshot and are loaded parents-first
regardless, so nothing is left dangling. `ANALYZE` runs afterwards.

`sh_load_csv.sql` uses `INSERT /*+ APPEND */` direct-path inserts, which is also what
makes the `COMPRESS` partition attributes on `sales` and `costs` take effect.

### Regenerating `sh_load_csv.sql`

That file is generated, not hand-written — every column name comes from the first line
of the matching CSV, so the `INSERT` lists cannot drift out of alignment with the DDL:

```bash
./oracle/tools/gen_sh_load_csv.sh
```

---

## Resource Requirements

Each service has a `mem_limit` in `docker-compose.yml` (enforced by plain
`docker compose up`, no Swarm required) so one engine can't starve the others.

| Engine | `mem_limit` | Typical RAM | Disk after seed | Notes |
|--------|-------------|-------------|-----------------|-------|
| PostgreSQL | `512m` | ~350 MB | ~900 MB | Raised from 384m for the employees load |
| MySQL | `1g` | ~450 MB | ~250 MB | 5 datasets, none of them large |
| SQL Server | `2g` | ~1.5 GB | ~500 MB | 60 s startup |
| Oracle XE | `3g` | ~2.5 GB | ~7 GB | Raised from 2.5g for SH |
| SQLite | `128m` | ~50 MB | ~15 MB | Instant |
| **Total** | **~6.6 GB** | **~5 GB** | **~8.7 GB** | |

> Give Docker Desktop at least **8 GB RAM**
> (Docker Desktop → Settings → Resources → Memory).
> If Oracle is OOM-killed during first-run init, `SH` is the likely trigger — check
> `docker inspect db_oracle --format '{{.State.OOMKilled}}'` and either raise
> `mem_limit` or set `ORACLE_SKIP_SH=true`.

---

## Health Checks

| Engine | Check |
|--------|-------|
| PostgreSQL | `pg_isready` |
| MySQL | `mysqladmin ping` |
| SQL Server | Gated on a `/tmp/seed_done` marker (written after Chinook + Northwind finish loading) **then** `SELECT 1` — avoids reporting healthy while still seeding |
| Oracle | `healthcheck.sh` (gvenzl image), `start_period: 1500s` to cover SH seeding |
| SQLite | `wget` against Datasette's `/-/versions.json` |

A healthcheck says the engine is *up*; `./verify.sh` says the data is *there*. Use both.

---

## Troubleshooting

**SQL Server won't start**
```bash
docker logs db_sqlserver
# Password must meet complexity: 8+ chars, upper, lower, digit, special
```

**Oracle takes too long**
```bash
docker logs -f db_oracle
# Normal: 3–5 min for CDB/PDB creation, then 10–20 min for SH.
# ORACLE_SKIP_SH=true removes the second part.
```

**Oracle `SH` printed a failure banner**
```bash
docker inspect db_oracle --format '{{.State.OOMKilled}}'   # true → raise mem_limit
docker logs db_oracle | grep -A5 'ORA-'
# Retry from scratch:
docker compose down && docker volume rm multidb_oracle_data && docker compose up -d oracle
```

**PostgreSQL `employees` is empty**
```bash
docker logs db_postgres | grep -A20 'Loading: employees'
# The load runs during init only. If it failed, re-seed:
docker compose stop postgres
docker volume rm multidb_postgres_data
docker compose up -d postgres
```

**Datasette shows no tables**
```bash
docker logs db_sqlite
```

**Force re-seed a single engine**
```bash
docker compose stop postgres
docker volume rm multidb_postgres_data
docker compose up -d postgres
```

---

## Smoke-Test Every Target

Fifteen one-liners, one per database/schema, all using the clients already inside the
containers — nothing to install. If these return numbers, your connection details are
right and the data is there.

```bash
# ── PostgreSQL: 6 databases ───────────────────────────────────────────────────
for db in chinook pagila employees northwind ecommerce world; do
  echo -n "$db: "
  docker exec db_postgres psql -U postgres -d "$db" -tAc \
    "SELECT count(*) || ' tables' FROM information_schema.tables
      WHERE table_schema = '$db' AND table_type = 'BASE TABLE';"
done

# ── SQL Server: 2 databases ───────────────────────────────────────────────────
docker exec db_sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'SqlServer123!' -No -d Chinook \
  -Q "SELECT COUNT(*) AS tracks FROM chinook.Track"
docker exec db_sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'SqlServer123!' -No -d Northwind \
  -Q "SELECT COUNT(*) AS products FROM northwind.Product"

# ── Oracle: 4 schemas ─────────────────────────────────────────────────────────
for u in chinook hr co sh; do
  echo -n "$u: "
  docker exec db_oracle sqlplus -s "$u/Oracle123!@//localhost/XEPDB1" <<'SQL'
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
SELECT COUNT(*) FROM user_tables;
EXIT;
SQL
done

# ── SQLite: 3 files ───────────────────────────────────────────────────────────
for db in chinook menagerie northwind; do
  echo -n "$db.db: "
  docker exec db_sqlite sqlite3 "/data/$db.db" \
    "SELECT COUNT(*) FROM sqlite_master WHERE type='table';"
done
```

Or just run [`./verify.sh`](verify.sh), which does all of this plus exact row counts and
schema-placement assertions.
