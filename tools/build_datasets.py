#!/usr/bin/env python3
# =============================================================================
# build_datasets.py — regenerate booking / bookstore / healthcare seed SQL
# =============================================================================
# The three newest datasets do not ship as ready-made per-engine dumps the way
# chinook or pagila do: their upstream sources are a pile of MySQL-flavoured
# scripts and loose CSVs under booking/ and healthcare/. This script is the one
# place that turns those sources into the five dialect-specific .sql files each
# engine's loader reads, so the 20+ MB of generated SQL in */data/ is
# reproducible rather than a mystery artifact.
#
#   python3 tools/build_datasets.py            # regenerate everything
#   python3 tools/build_datasets.py booking    # one dataset only
#
# ── Design notes ─────────────────────────────────────────────────────────────
# * Every primary key is written out explicitly, so no engine needs IDENTITY /
#   SERIAL / sequences+triggers and there is no sequence to resync afterwards.
# * Foreign keys are validated against the actual rows before they are emitted.
#   Orphan rows are dropped (and reported) rather than left to blow up a load
#   halfway through — the upstream CSVs are not internally consistent.
# * Table and column names are lower-cased everywhere. Oracle folds unquoted
#   identifiers to upper case, which is what verify.sh expects there.
# =============================================================================
from __future__ import annotations

import csv
import re
import sys
from dataclasses import dataclass, field
from decimal import Decimal
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BOOKING_SRC = ROOT / "booking"
HEALTH_SRC = ROOT / "healthcare"

DIALECTS = ("mysql", "postgres", "mssql", "oracle", "sqlite")

# Where each dialect's output lands, and how the file is named.
OUTPUT = {
    "mysql":    ("mysql/data/{ds}",     "{ds}.sql"),
    "postgres": ("postgres/data/{ds}",  "{ds}_pg.sql"),
    "mssql":    ("sqlserver/data/{ds}", "{ds}_mssql.sql"),
    "oracle":   ("oracle/data/{ds}",    "{ds}_oracle.sql"),
    "sqlite":   ("sqlite/data/{ds}",    "{ds}_sqlite.sql"),
}


# ─── Schema model ────────────────────────────────────────────────────────────

@dataclass
class Column:
    name: str
    type: str                 # int | bool | date | time | text | varchar(n) | char(n) | dec(p,s)
    nullable: bool = True


@dataclass
class Table:
    name: str
    columns: list[Column]
    pk: tuple[str, ...] = ()
    fks: list[tuple[tuple[str, ...], str, tuple[str, ...]]] = field(default_factory=list)
    rows: list[list] = field(default_factory=list)

    def index(self, col: str) -> int:
        for i, c in enumerate(self.columns):
            if c.name == col:
                return i
        raise KeyError(f"{self.name}.{col}")

    def colnames(self) -> list[str]:
        return [c.name for c in self.columns]


@dataclass
class Dataset:
    name: str                 # booking | bookstore | healthcare
    db_name: str              # SQL Server database name (Booking, Bookstore, …)
    tables: list[Table]       # parents first — creation and load order
    description: str


# ─── Type + literal rendering ────────────────────────────────────────────────

_SCALAR_TYPES = {
    "int":  dict(mysql="INT", postgres="INTEGER", mssql="INT",
                 oracle="NUMBER(10)", sqlite="INTEGER"),
    "bool": dict(mysql="TINYINT(1)", postgres="BOOLEAN", mssql="BIT",
                 oracle="NUMBER(1)", sqlite="INTEGER"),
    "date": dict(mysql="DATE", postgres="DATE", mssql="DATE",
                 oracle="DATE", sqlite="TEXT"),
    "time": dict(mysql="TIME", postgres="TIME", mssql="TIME",
                 oracle="VARCHAR2(8)", sqlite="TEXT"),
    # No LOBs: CLOB / NVARCHAR(MAX) are awkward to GROUP BY and none of this
    # free text is anywhere near 4 000 characters.
    "text": dict(mysql="TEXT", postgres="TEXT", mssql="NVARCHAR(4000)",
                 oracle="VARCHAR2(4000)", sqlite="TEXT"),
}


def sql_type(t: str, dialect: str) -> str:
    if t in _SCALAR_TYPES:
        return _SCALAR_TYPES[t][dialect]
    m = re.fullmatch(r"varchar\((\d+)\)", t)
    if m:
        n = m.group(1)
        return {"mysql": f"VARCHAR({n})", "postgres": f"VARCHAR({n})",
                "mssql": f"NVARCHAR({n})", "oracle": f"VARCHAR2({n})",
                "sqlite": "TEXT"}[dialect]
    m = re.fullmatch(r"char\((\d+)\)", t)
    if m:
        n = m.group(1)
        return {"mysql": f"CHAR({n})", "postgres": f"CHAR({n})",
                "mssql": f"NCHAR({n})", "oracle": f"CHAR({n})",
                "sqlite": "TEXT"}[dialect]
    m = re.fullmatch(r"dec\((\d+),(\d+)\)", t)
    if m:
        p, s = m.groups()
        return {"mysql": f"DECIMAL({p},{s})", "postgres": f"NUMERIC({p},{s})",
                "mssql": f"DECIMAL({p},{s})", "oracle": f"NUMBER({p},{s})",
                "sqlite": "NUMERIC"}[dialect]
    raise ValueError(f"unknown type {t!r}")


def literal(value, ctype: str, dialect: str) -> str:
    if value is None or value == "":
        return "NULL"

    base = ctype.split("(")[0]

    if base == "bool":
        truthy = str(value).strip().lower() in ("1", "true", "t", "yes", "y")
        return ("TRUE" if truthy else "FALSE") if dialect == "postgres" else ("1" if truthy else "0")

    if base == "int":
        return str(int(value))

    if base == "dec":
        return str(Decimal(str(value)))

    if base == "date":
        v = str(value).strip()
        # Some sources hand back a full timestamp for a DATE column
        # ("2023-02-02 00:00:00"). Every other engine casts that to a date
        # silently, so it went unnoticed; Oracle raises ORA-01830 ("date format
        # picture ends before converting entire input string") because the mask
        # below covers only the date part. Keeping just that part matches both
        # the mask and the column type the DDL declares.
        v = v.replace("T", " ").split(" ")[0]
        return f"TO_DATE('{v}','YYYY-MM-DD')" if dialect == "oracle" else f"'{v}'"

    if base == "time":
        v = str(value).strip()
        # The CSVs write 9:00 where the SQL sources write 09:00:00.
        parts = v.split(":")
        if len(parts) == 2:
            parts.append("00")
        v = ":".join(p.zfill(2) for p in parts)
        return f"'{v}'"

    # Character data
    s = str(value)
    if dialect == "mysql":
        # MySQL treats backslash as an escape character inside string literals.
        s = s.replace("\\", "\\\\")
    s = s.replace("'", "''")
    if dialect == "mssql":
        return f"N'{s}'"          # the clinic notes contain non-ASCII punctuation
    return f"'{s}'"


# ─── Identifier quoting ──────────────────────────────────────────────────────

def qtable(ds: Dataset, table: str, dialect: str) -> str:
    if dialect == "mysql":
        return f"`{table}`"
    if dialect == "mssql":
        return f"[{ds.name}].[{table}]"
    return table                      # postgres search_path / oracle user / sqlite file


def qcol(col: str, dialect: str) -> str:
    if dialect == "mysql":
        return f"`{col}`"
    if dialect == "mssql":
        return f"[{col}]"
    return col


# ─── Source parsing helpers ──────────────────────────────────────────────────

_INSERT_RE = re.compile(
    r"INSERT\s+INTO\s+[`\"\[]?(\w+)[`\"\]]?\s*\(([^)]*)\)\s*VALUES\s*(.*?);",
    re.IGNORECASE | re.DOTALL,
)


def _unliteral(tok: str):
    """One raw SQL literal → a Python value."""
    tok = tok.strip()
    if not tok or tok.upper() == "NULL":
        return None
    if tok[0] in ("'", '"') and tok[-1] == tok[0]:
        q = tok[0]
        body = tok[1:-1]
        body = body.replace(q + q, q)
        body = re.sub(r"\\(.)", r"\1", body)
        return body
    try:
        return int(tok)
    except ValueError:
        pass
    try:
        return float(tok)
    except ValueError:
        return tok


def _split_tuples(blob: str) -> list[list]:
    """The `(…),(…),(…)` body of a VALUES clause → list of value lists."""
    rows, i, n = [], 0, len(blob)
    while i < n:
        if blob[i] != "(":
            i += 1
            continue
        i += 1
        vals, buf, quote = [], "", ""
        while i < n:
            c = blob[i]
            if quote:
                if c == "\\" and i + 1 < n:
                    buf += blob[i:i + 2]
                    i += 2
                    continue
                if c == quote:
                    if i + 1 < n and blob[i + 1] == quote:
                        buf += c * 2
                        i += 2
                        continue
                    quote = ""
                buf += c
                i += 1
                continue
            if c in ("'", '"'):
                quote = c
                buf += c
                i += 1
                continue
            if c == ",":
                vals.append(buf)
                buf = ""
                i += 1
                continue
            if c == ")":
                vals.append(buf)
                i += 1
                break
            buf += c
            i += 1
        rows.append([_unliteral(v) for v in vals])
    return rows


def parse_inserts(path: Path) -> dict[str, list[tuple[list[str], list[list]]]]:
    """All INSERT statements in a file, keyed by lower-cased table name."""
    text = path.read_text(encoding="utf-8", errors="replace")
    out: dict[str, list[tuple[list[str], list[list]]]] = {}
    for m in _INSERT_RE.finditer(text):
        table = m.group(1).lower()
        cols = [c.strip().strip('`"[]').lower() for c in m.group(2).split(",")]
        out.setdefault(table, []).append((cols, _split_tuples(m.group(3))))
    return out


def rows_from(inserts, table: str, target_cols: list[str], synth_pk: str | None = None) -> list[list]:
    """Re-project parsed INSERT rows onto `target_cols`.

    `synth_pk` names a column the source omits because it was AUTO_INCREMENT;
    it is filled in with 1..N in source order.
    """
    out: list[list] = []
    counter = 0
    for cols, tuples in inserts.get(table, []):
        for t in tuples:
            src = dict(zip(cols, t))
            if synth_pk and synth_pk not in src:
                counter += 1
                src[synth_pk] = counter
            out.append([src.get(c) for c in target_cols])
    return out


def read_csv(path: Path, target_cols: list[str], rename: dict[str, str] | None = None) -> list[list]:
    rename = rename or {}
    out = []
    with path.open(newline="", encoding="utf-8-sig", errors="replace") as fh:
        for rec in csv.DictReader(fh):
            row = {}
            for k, v in rec.items():
                if k is None:
                    continue
                key = rename.get(k.strip().lower(), k.strip().lower())
                if v is None or v.strip() in ("", "NULL", "NA", "null"):
                    row[key] = None
                else:
                    row[key] = v.strip()
            out.append([row.get(c) for c in target_cols])
    return out


# ─── Referential cleanup ─────────────────────────────────────────────────────

def key_value(value, ctype: str):
    """A cell in the comparable form the database will actually see.

    Raw cells are not comparable across sources: the SQL dumps yield an id as
    int 1 where the CSVs yield the same id as str '1', so `(1,) != ('1',)` even
    though literal() renders both as `1` and the engine treats them as one key.
    Comparing raw tuples therefore let duplicate primary keys through and made
    valid foreign keys look dangling.
    """
    if value is None or value == "":
        return None
    base = ctype.split("(")[0]
    if base == "int":
        return int(value)
    if base == "dec":
        return Decimal(str(value))
    if base == "bool":
        return str(value).strip().lower() in ("1", "true", "t", "yes", "y")
    return str(value).strip()


def row_key(t: Table, idx: list[int], row: list) -> tuple:
    return tuple(key_value(row[i], t.columns[i].type) for i in idx)


def enforce_fks(ds: Dataset) -> None:
    """Drop rows whose foreign keys point at nothing, loudly.

    The upstream CSVs reference ids that were never exported. Emitting the
    constraint and letting the engine reject the load mid-file would leave a
    half-populated schema, so the rows are removed here instead.
    """
    by_name = {t.name: t for t in ds.tables}
    for t in ds.tables:
        for cols, ref_table, ref_cols in t.fks:
            parent = by_name[ref_table]
            pidx = [parent.index(c) for c in ref_cols]
            known = {row_key(parent, pidx, r) for r in parent.rows}
            cidx = [t.index(c) for c in cols]
            kept, dropped = [], 0
            for r in t.rows:
                key = row_key(t, cidx, r)
                if any(v is None for v in key) or key in known:
                    kept.append(r)
                else:
                    dropped += 1
            if dropped:
                print(f"    ! {ds.name}.{t.name}: dropped {dropped} row(s) "
                      f"with no matching {ref_table}({', '.join(ref_cols)})")
            t.rows = kept

    # Duplicate primary keys would fail the same way.
    for t in ds.tables:
        if not t.pk:
            continue
        idx = [t.index(c) for c in t.pk]
        seen, kept, dropped = set(), [], 0
        for r in t.rows:
            key = row_key(t, idx, r)
            if key in seen:
                dropped += 1
                continue
            seen.add(key)
            kept.append(r)
        if dropped:
            print(f"    ! {ds.name}.{t.name}: dropped {dropped} duplicate primary key(s)")
        t.rows = kept


# ─── Emitters ────────────────────────────────────────────────────────────────

BATCH = {"mysql": 500, "postgres": 500, "mssql": 500, "oracle": 100, "sqlite": 500}


def split_fks(ds: Dataset, t: Table, dialect: str) -> tuple[list, list]:
    """Partition t.fks into (inline, deferred), keeping each one's 1-based index.

    An FK that points at a table declared *later* than this one cannot be
    inline: the referenced table does not exist yet at CREATE TABLE time. That
    only happens when the graph has a cycle — healthcare's departments carries
    headofdepartment → medicalstaff while medicalstaff points back at
    departments — and one of the two has to be broken out into a trailing
    ALTER TABLE. Deferring it past the inserts also means both sides are
    populated before the constraint is validated.

    SQLite is exempt: it has no ALTER TABLE ADD CONSTRAINT, and it does not
    resolve REFERENCES at CREATE TABLE time anyway, so a forward reference is
    already legal there.
    """
    if dialect == "sqlite":
        return list(enumerate(t.fks, 1)), []
    order = {tbl.name: i for i, tbl in enumerate(ds.tables)}
    mine = order[t.name]
    inline, deferred = [], []
    for i, fk in enumerate(t.fks, 1):
        (deferred if order.get(fk[1], -1) > mine else inline).append((i, fk))
    return inline, deferred


def emit_create(ds: Dataset, t: Table, dialect: str) -> str:
    lines = []
    for c in t.columns:
        null = "" if c.nullable else " NOT NULL"
        lines.append(f"    {qcol(c.name, dialect)} {sql_type(c.type, dialect)}{null}")
    if t.pk:
        cols = ", ".join(qcol(c, dialect) for c in t.pk)
        lines.append(f"    CONSTRAINT pk_{t.name} PRIMARY KEY ({cols})")
    for i, (cols, ref, refcols) in split_fks(ds, t, dialect)[0]:
        c = ", ".join(qcol(x, dialect) for x in cols)
        rc = ", ".join(qcol(x, dialect) for x in refcols)
        lines.append(f"    CONSTRAINT fk_{t.name}_{i} FOREIGN KEY ({c}) "
                     f"REFERENCES {qtable(ds, ref, dialect)} ({rc})")
    body = ",\n".join(lines)
    suffix = " ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" if dialect == "mysql" else ""
    return f"CREATE TABLE {qtable(ds, t.name, dialect)} (\n{body}\n){suffix};"


def emit_deferred_fks(ds: Dataset, dialect: str) -> list[str]:
    """The forward-referencing FKs split_fks() held back, as ALTER TABLE."""
    out: list[str] = []
    for t in ds.tables:
        for i, (cols, ref, refcols) in split_fks(ds, t, dialect)[1]:
            c = ", ".join(qcol(x, dialect) for x in cols)
            rc = ", ".join(qcol(x, dialect) for x in refcols)
            out.append(f"ALTER TABLE {qtable(ds, t.name, dialect)} "
                       f"ADD CONSTRAINT fk_{t.name}_{i} FOREIGN KEY ({c}) "
                       f"REFERENCES {qtable(ds, ref, dialect)} ({rc});")
    if out and dialect == "mssql":
        out.append("GO")
    return out + [""] if out else out


def emit_inserts(ds: Dataset, t: Table, dialect: str) -> list[str]:
    if not t.rows:
        return []
    cols = ", ".join(qcol(c, dialect) for c in t.colnames())
    types = [c.type for c in t.columns]
    target = qtable(ds, t.name, dialect)
    size = BATCH[dialect]
    out = []

    for start in range(0, len(t.rows), size):
        chunk = t.rows[start:start + size]
        if dialect == "oracle":
            # Oracle has no multi-row VALUES; INSERT ALL is the portable form.
            # The column list is omitted deliberately — every column is emitted,
            # in declaration order, and repeating 33 column names on each of
            # 119 000 rows quadruples the file size for no benefit.
            body = "\n".join(
                f"  INTO {target} VALUES ("
                + ", ".join(literal(v, ty, dialect) for v, ty in zip(r, types)) + ")"
                for r in chunk
            )
            out.append(f"INSERT ALL\n{body}\nSELECT * FROM dual;")
        else:
            body = ",\n".join(
                "  (" + ", ".join(literal(v, ty, dialect) for v, ty in zip(r, types)) + ")"
                for r in chunk
            )
            out.append(f"INSERT INTO {target} ({cols}) VALUES\n{body};")
    return out


def build_file(ds: Dataset, dialect: str) -> str:
    head = [
        "-- " + "=" * 74,
        f"-- {ds.name} — {ds.description}",
        f"-- GENERATED by tools/build_datasets.py — do not edit by hand.",
        f"-- Dialect: {dialect}. Tables: {len(ds.tables)}. "
        f"Rows: {sum(len(t.rows) for t in ds.tables):,}.",
        "-- " + "=" * 74,
        "",
    ]
    parts: list[str] = []
    drops = [t.name for t in reversed(ds.tables)]

    if dialect == "mysql":
        parts += [f"CREATE DATABASE IF NOT EXISTS `{ds.name}` "
                  f"DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;",
                  f"USE `{ds.name}`;",
                  "SET FOREIGN_KEY_CHECKS = 0;",
                  "SET autocommit = 0;",
                  ""]
        parts += [f"DROP TABLE IF EXISTS `{n}`;" for n in drops] + [""]
    elif dialect == "postgres":
        # The loader has already set search_path to the dataset schema.
        parts += [f"DROP TABLE IF EXISTS {n} CASCADE;" for n in drops] + [""]
    elif dialect == "sqlite":
        parts += ["PRAGMA foreign_keys = OFF;", "BEGIN TRANSACTION;", ""]
        parts += [f"DROP TABLE IF EXISTS {n};" for n in drops] + [""]
    elif dialect == "mssql":
        parts += [f"IF DB_ID(N'{ds.db_name}') IS NULL CREATE DATABASE [{ds.db_name}];",
                  "GO",
                  f"USE [{ds.db_name}];",
                  "GO",
                  f"IF SCHEMA_ID(N'{ds.name}') IS NULL EXEC('CREATE SCHEMA [{ds.name}]');",
                  "GO",
                  "SET NOCOUNT ON;",
                  "GO",
                  ""]
        # Strip every FK in the schema before dropping anything. The other
        # dialects get this for free (FOREIGN_KEY_CHECKS = 0, CASCADE,
        # CASCADE CONSTRAINTS); T-SQL has no equivalent, so reverse-declaration
        # order is the only ordering available — and that is not a valid drop
        # order once the graph has a cycle (a dataset whose parent table carries
        # an FK back to a child, emitted as a trailing ALTER TABLE). Dropping
        # the constraints first makes the table order irrelevant.
        parts += ["DECLARE @drop_fks nvarchar(max) = N'';",
                  "SELECT @drop_fks = @drop_fks + N'ALTER TABLE [' + s.name + N'].['"
                  " + t.name + N'] DROP CONSTRAINT [' + fk.name + N'];'",
                  "  FROM sys.foreign_keys fk",
                  "  JOIN sys.tables t   ON t.object_id = fk.parent_object_id",
                  "  JOIN sys.schemas s  ON s.schema_id = t.schema_id",
                  f" WHERE s.name = N'{ds.name}';",
                  "EXEC sp_executesql @drop_fks;",
                  "GO",
                  ""]
        parts += [f"IF OBJECT_ID(N'[{ds.name}].[{n}]', N'U') IS NOT NULL "
                  f"DROP TABLE [{ds.name}].[{n}];" for n in drops] + ["GO", ""]
    elif dialect == "oracle":
        names = ", ".join(f"'{n.upper()}'" for n in drops)
        parts += ["SET DEFINE OFF",
                  "SET SQLBLANKLINES ON",
                  "SET FEEDBACK OFF",
                  "",
                  "BEGIN",
                  f"    FOR r IN (SELECT table_name FROM user_tables "
                  f"WHERE table_name IN ({names})) LOOP",
                  "        EXECUTE IMMEDIATE 'DROP TABLE \"' || r.table_name || "
                  "'\" CASCADE CONSTRAINTS';",
                  "    END LOOP;",
                  "END;",
                  "/",
                  ""]

    for t in ds.tables:
        parts.append(emit_create(ds, t, dialect))
        if dialect == "mssql":
            parts.append("GO")
        parts.append("")

    stmt_count = 0
    for t in ds.tables:
        if not t.rows:
            continue
        parts.append(f"-- {t.name}: {len(t.rows):,} rows")
        for stmt in emit_inserts(ds, t, dialect):
            parts.append(stmt)
            stmt_count += 1
            # One GO per INSERT, not per 100. SQL Server compiles a whole batch
            # before executing any of it, so 100 statements x BATCH rows x every
            # column lands ~1.6 M scalar expressions in a single plan — the
            # optimizer runs out of memory in the 2 GB container and aborts the
            # *entire* batch, leaving the tables created and completely empty.
            if dialect == "mssql":
                parts.append("GO")
            if dialect == "oracle" and stmt_count % 50 == 0:
                parts.append("COMMIT;")
            if dialect == "mysql" and stmt_count % 100 == 0:
                parts.append("COMMIT;")
        parts.append("")

    parts += emit_deferred_fks(ds, dialect)

    if dialect == "mysql":
        parts += ["COMMIT;", "SET autocommit = 1;", "SET FOREIGN_KEY_CHECKS = 1;"]
    elif dialect == "sqlite":
        parts += ["COMMIT;", "PRAGMA foreign_keys = ON;"]
    elif dialect == "mssql":
        parts += ["GO"]
    elif dialect == "oracle":
        parts += ["COMMIT;", "EXIT;"]

    return "\n".join(head + parts) + "\n"


# ─── Dataset: booking ────────────────────────────────────────────────────────

HOTEL_BOOKINGS_COLUMNS = [
    ("booking_id", "int", False),
    ("hotel", "varchar(50)", False),
    ("is_canceled", "int", False),
    ("lead_time", "int", True),
    ("arrival_date_year", "int", True),
    ("arrival_date_month", "varchar(20)", True),
    ("arrival_date_week_number", "int", True),
    ("arrival_date_day_of_month", "int", True),
    ("stays_in_weekend_nights", "int", True),
    ("stays_in_week_nights", "int", True),
    ("adults", "int", True),
    ("children", "int", True),
    ("babies", "int", True),
    ("meal", "varchar(20)", True),
    ("country", "varchar(10)", True),
    ("market_segment", "varchar(40)", True),
    ("distribution_channel", "varchar(40)", True),
    ("is_repeated_guest", "int", True),
    ("previous_cancellations", "int", True),
    ("previous_bookings_not_canceled", "int", True),
    ("reserved_room_type", "varchar(5)", True),
    ("assigned_room_type", "varchar(5)", True),
    ("booking_changes", "int", True),
    ("deposit_type", "varchar(30)", True),
    ("agent", "int", True),
    ("company", "int", True),
    ("days_in_waiting_list", "int", True),
    ("customer_type", "varchar(30)", True),
    ("adr", "dec(10,2)", True),
    ("required_car_parking_spaces", "int", True),
    ("total_of_special_requests", "int", True),
    ("reservation_status", "varchar(20)", True),
    ("reservation_status_date", "date", True),
]


def build_booking() -> Dataset:
    hotel_dir = BOOKING_SRC / "Hotel-Reservation-Database-SQL-master"
    data = parse_inserts(hotel_dir / "EricRiddle-HotelData.sql")
    toy = parse_inserts(BOOKING_SRC / "Hotel-Reservation-database-master" / "all.sql")

    room = Table("room", [
        Column("roomnumber", "int", False),
        Column("roomtype", "varchar(10)", False),
        Column("isada", "bool", False),
        Column("standardoccupancy", "int", False),
        Column("maximumoccupancy", "int", False),
        Column("baseprice", "dec(7,2)", False),
        Column("extraperson", "dec(6,2)", False),
        Column("hasjacuzzi", "bool", False),
    ], pk=("roomnumber",))
    room.rows = rows_from(data, "room", room.colnames())

    amenity = Table("amenity", [
        Column("amenityid", "int", False),
        Column("amenitytype", "varchar(30)"),
    ], pk=("amenityid",))
    amenity.rows = rows_from(data, "amenity", amenity.colnames(), synth_pk="amenityid")

    roomamenity = Table("roomamenity", [
        Column("roomnumber", "int", False),
        Column("amenityid", "int", False),
    ], pk=("roomnumber", "amenityid"), fks=[
        (("roomnumber",), "room", ("roomnumber",)),
        (("amenityid",), "amenity", ("amenityid",)),
    ])
    roomamenity.rows = rows_from(data, "roomamenity", roomamenity.colnames())

    guest = Table("guest", [
        Column("guestid", "int", False),
        Column("firstname", "varchar(50)", False),
        Column("lastname", "varchar(50)", False),
        Column("street", "varchar(100)"),
        Column("city", "varchar(50)"),
        Column("state", "char(2)"),
        Column("zip", "char(5)"),
        Column("phone", "varchar(14)"),
    ], pk=("guestid",))
    guest.rows = rows_from(data, "guest", guest.colnames(), synth_pk="guestid")

    reservation = Table("reservation", [
        Column("reservationid", "int", False),
        Column("adults", "int", False),
        Column("children", "int", False),
        Column("checkindate", "date"),
        Column("checkoutdate", "date"),
        Column("total", "dec(8,2)", False),
    ], pk=("reservationid",))
    reservation.rows = rows_from(data, "reservation", reservation.colnames(),
                                 synth_pk="reservationid")

    # The source ends by deleting guest 8 and reservation 8 ("Removing Jeremiah
    # Pendergrass and his reservations"). Applying it here keeps the row counts
    # honest; enforce_fks() then clears the join rows that pointed at them.
    guest.rows = [r for r in guest.rows if r[0] != 8]
    reservation.rows = [r for r in reservation.rows if r[0] != 8]

    guestreservation = Table("guestreservation", [
        Column("guestid", "int", False),
        Column("reservationid", "int", False),
    ], pk=("guestid", "reservationid"), fks=[
        (("guestid",), "guest", ("guestid",)),
        (("reservationid",), "reservation", ("reservationid",)),
    ])
    guestreservation.rows = rows_from(data, "guestreservation", guestreservation.colnames())

    roomreservation = Table("roomreservation", [
        Column("roomnumber", "int", False),
        Column("reservationid", "int", False),
    ], pk=("roomnumber", "reservationid"), fks=[
        (("roomnumber",), "room", ("roomnumber",)),
        (("reservationid",), "reservation", ("reservationid",)),
    ])
    roomreservation.rows = rows_from(data, "roomreservation", roomreservation.colnames())

    # Hotel-Reservation-database-master models the same domain a second time and
    # far more crudely; only its staff list adds anything the schema above lacks.
    staff = Table("staff", [
        Column("staffid", "int", False),
        Column("firstname", "varchar(100)"),
        Column("lastname", "varchar(100)"),
        Column("salary", "int", False),
    ], pk=("staffid",))
    staff.rows = rows_from(toy, "employee", ["employee_id", "first_name", "last_name", "salary"],
                           synth_pk="employee_id")

    hotel_bookings = Table(
        "hotel_bookings",
        [Column(n, t, nul) for n, t, nul in HOTEL_BOOKINGS_COLUMNS],
        pk=("booking_id",),
    )
    csv_path = (BOOKING_SRC / "DataCleaningAndExploration-with-SQL-HotelBookings-dataset-main"
                / "hotel_bookings.csv")
    raw = read_csv(csv_path, [c[0] for c in HOTEL_BOOKINGS_COLUMNS])
    for i, r in enumerate(raw, 1):
        r[0] = i
    hotel_bookings.rows = raw

    return Dataset(
        "booking", "Booking",
        [room, amenity, roomamenity, guest, reservation,
         guestreservation, roomreservation, staff, hotel_bookings],
        "Hotel reservations — a normalised booking system plus 119k historical stays",
    )


# ─── Dataset: bookstore ──────────────────────────────────────────────────────

def build_bookstore() -> Dataset:
    # Despite its filename, hotel_chain_management_system.sql is an online book
    # publishing / sales schema. It gets its own dataset rather than being
    # folded into booking, where nothing would join to it.
    src = parse_inserts(BOOKING_SRC / "hotel_chain_management_system.sql")

    publisher = Table("publisher", [
        Column("publisherid", "int", False),
        Column("name", "varchar(100)", False),
        Column("contactdetails", "varchar(255)"),
    ], pk=("publisherid",))
    publisher.rows = rows_from(src, "publisher", publisher.colnames())

    book = Table("book", [
        Column("bookid", "int", False),
        Column("title", "varchar(200)", False),
        Column("isbn", "varchar(20)", False),
        Column("edition", "int", False),
        Column("publicationyear", "int"),
        Column("price", "dec(10,2)"),
        Column("publisherid", "int"),
    ], pk=("bookid",), fks=[(("publisherid",), "publisher", ("publisherid",))])
    book.rows = rows_from(src, "book", book.colnames())

    genre = Table("genre", [
        Column("genreid", "int", False),
        Column("genrename", "varchar(100)", False),
    ], pk=("genreid",))
    genre.rows = rows_from(src, "genre", genre.colnames())

    bookgenre = Table("bookgenre", [
        Column("bookid", "int", False),
        Column("genreid", "int", False),
    ], pk=("bookid", "genreid"), fks=[
        (("bookid",), "book", ("bookid",)),
        (("genreid",), "genre", ("genreid",)),
    ])
    bookgenre.rows = rows_from(src, "bookgenre", bookgenre.colnames())

    # The source spells the Author primary key "AuthouID" but references it as
    # AuthorID everywhere else; normalised here.
    author = Table("author", [
        Column("authorid", "int", False),
        Column("name", "varchar(100)", False),
        Column("biography", "text"),
    ], pk=("authorid",))
    author.rows = rows_from(src, "author", ["authouid", "name", "biography"])

    bookauthor = Table("bookauthor", [
        Column("bookid", "int", False),
        Column("authorid", "int", False),
    ], pk=("bookid", "authorid"), fks=[
        (("bookid",), "book", ("bookid",)),
        (("authorid",), "author", ("authorid",)),
    ])
    bookauthor.rows = rows_from(src, "bookauthor", bookauthor.colnames())

    customer = Table("customer", [
        Column("customerid", "int", False),
        Column("name", "varchar(100)", False),
    ], pk=("customerid",))
    customer.rows = rows_from(src, "customer", customer.colnames())

    address = Table("address", [
        Column("addressid", "int", False),
        Column("customerid", "int"),
        Column("street", "varchar(100)"),
        Column("city", "varchar(100)"),
        Column("state", "varchar(100)"),
        Column("country", "varchar(100)"),
    ], pk=("addressid",), fks=[(("customerid",), "customer", ("customerid",))])
    address.rows = rows_from(src, "address", address.colnames())

    wishlist = Table("wishlist", [
        Column("customerid", "int", False),
        Column("bookid", "int", False),
    ], pk=("customerid", "bookid"), fks=[
        (("customerid",), "customer", ("customerid",)),
        (("bookid",), "book", ("bookid",)),
    ])
    wishlist.rows = rows_from(src, "whishlist", wishlist.colnames())

    # Orderr → orders; ShippingAddressID in the FK clause is a typo for the
    # ShipmentAddressID column the table actually declares.
    orders = Table("orders", [
        Column("orderid", "int", False),
        Column("orderdate", "date", False),
        Column("customerid", "int"),
        Column("paymentdetails", "varchar(255)"),
        Column("shipmentstatus", "varchar(50)"),
        Column("shipmentaddressid", "int"),
    ], pk=("orderid",), fks=[
        (("customerid",), "customer", ("customerid",)),
        (("shipmentaddressid",), "address", ("addressid",)),
    ])
    orders.rows = rows_from(src, "orderr", orders.colnames())

    order_book = Table("order_book", [
        Column("orderitemid", "int", False),
        Column("orderid", "int"),
        Column("bookid", "int"),
        Column("quantity", "int", False),
        Column("itemdiscount", "dec(5,2)"),
    ], pk=("orderitemid",), fks=[
        (("orderid",), "orders", ("orderid",)),
        (("bookid",), "book", ("bookid",)),
    ])
    order_book.rows = rows_from(src, "order_book", order_book.colnames())

    return Dataset(
        "bookstore", "Bookstore",
        [publisher, book, genre, bookgenre, author, bookauthor,
         customer, address, wishlist, orders, order_book],
        "Online book publishing and sales — catalogue, customers, wishlists, orders",
    )


# ─── Dataset: healthcare ─────────────────────────────────────────────────────

def build_healthcare() -> Dataset:
    clinic = HEALTH_SRC / "Medical-Clinic-Database-SQL-main"
    sql = parse_inserts(clinic / "sql folder" / "Database SQL file.sql")
    csv_dir = clinic / "csv folder"

    departments = Table("departments", [
        Column("departmentid", "int", False),
        Column("departmentname", "varchar(100)", False),
        Column("description", "text"),
        Column("headofdepartment", "int"),
        Column("contactnumber", "varchar(15)"),
        Column("email", "varchar(100)"),
    ], pk=("departmentid",))
    dept_cols = ["departmentid", "departmentname", "description",
                 "headofdepartment", "contactnumber", "email"]
    departments.rows = (rows_from(sql, "departments", dept_cols)
                        + read_csv(csv_dir / "Departments.csv", dept_cols))

    medicalstaff = Table("medicalstaff", [
        Column("medstaffid", "int", False),
        Column("firstname", "varchar(100)", False),
        Column("lastname", "varchar(100)", False),
        Column("role", "varchar(50)"),
        Column("departmentid", "int"),
        Column("phone", "varchar(15)"),
        Column("email", "varchar(100)"),
        Column("hiredate", "date"),
        Column("status", "varchar(20)"),
    ], pk=("medstaffid",), fks=[(("departmentid",), "departments", ("departmentid",))])
    medicalstaff.rows = (rows_from(sql, "medicalstaff", medicalstaff.colnames())
                         + read_csv(csv_dir / "MedicalStaff.csv", medicalstaff.colnames()))

    # departments.headofdepartment points back at medicalstaff, so the constraint
    # can only be added once both are populated — it is declared on the child.
    departments.fks = [(("headofdepartment",), "medicalstaff", ("medstaffid",))]

    nonmedicalstaff = Table("nonmedicalstaff", [
        Column("staffid", "int", False),
        Column("firstname", "varchar(100)", False),
        Column("lastname", "varchar(100)", False),
        Column("role", "varchar(50)"),
        Column("departmentid", "int"),
        Column("phone", "varchar(15)"),
        Column("email", "varchar(100)"),
        Column("hiredate", "date"),
        Column("status", "varchar(20)"),
    ], pk=("staffid",), fks=[(("departmentid",), "departments", ("departmentid",))])
    nonmedicalstaff.rows = (rows_from(sql, "nonmedicalstaff", nonmedicalstaff.colnames())
                            + read_csv(csv_dir / "NonMedicalStaff.csv", nonmedicalstaff.colnames()))

    patients = Table("patients", [
        Column("patientid", "int", False),
        Column("firstname", "varchar(100)", False),
        Column("lastname", "varchar(100)", False),
        Column("gender", "varchar(10)"),
        Column("dob", "date"),
        Column("phone", "varchar(15)"),
        Column("email", "varchar(100)"),
        Column("address", "varchar(255)"),
        Column("bloodtype", "varchar(3)"),
        Column("registrationdate", "date"),
    ], pk=("patientid",))
    patients.rows = (rows_from(sql, "patients", patients.colnames())
                     + read_csv(csv_dir / "Patients.csv", patients.colnames()))

    appointments = Table("appointments", [
        Column("appointmentid", "int", False),
        Column("patientid", "int", False),
        Column("medstaffid", "int", False),
        Column("appointmentdate", "date"),
        Column("appointmenttime", "time"),
        Column("visittype", "varchar(20)"),
        Column("status", "varchar(20)"),
        Column("notes", "text"),
    ], pk=("appointmentid",), fks=[
        (("patientid",), "patients", ("patientid",)),
        (("medstaffid",), "medicalstaff", ("medstaffid",)),
    ])
    appointments.rows = (rows_from(sql, "appointments", appointments.colnames())
                         + read_csv(csv_dir / "Appointments.csv", appointments.colnames()))

    # Prescriptions / MedicalRecords / Allergies ship without a key of their own;
    # a surrogate keeps every table addressable and lets verify.sh count them.
    prescriptions = Table("prescriptions", [
        Column("prescriptionid", "int", False),
        Column("appointmentid", "int"),
        Column("medicationname", "varchar(100)"),
        Column("startdate", "date"),
        Column("enddate", "date"),
        Column("dosage", "varchar(50)"),
        Column("instructions", "text"),
    ], pk=("prescriptionid",), fks=[(("appointmentid",), "appointments", ("appointmentid",))])
    pres_cols = ["appointmentid", "medicationname", "startdate", "enddate", "dosage", "instructions"]
    pres = (rows_from(sql, "prescriptions", pres_cols)
            + read_csv(csv_dir / "Prescriptions.csv", pres_cols))
    prescriptions.rows = [[i] + r for i, r in enumerate(pres, 1)]

    medicalrecords = Table("medicalrecords", [
        Column("recordid", "int", False),
        Column("patientid", "int", False),
        Column("medstaffid", "int", False),
        Column("lastvisitdate", "date"),
        Column("diagnosis", "text"),
        Column("nextvisit", "date"),
    ], pk=("recordid",), fks=[
        (("patientid",), "patients", ("patientid",)),
        (("medstaffid",), "medicalstaff", ("medstaffid",)),
    ])
    mr_cols = ["patientid", "medstaffid", "lastvisitdate", "diagnosis", "nextvisit"]
    mr = (rows_from(sql, "medicalrecords", mr_cols)
          + read_csv(csv_dir / "MedicalRecords.csv", mr_cols))
    medicalrecords.rows = [[i] + r for i, r in enumerate(mr, 1)]

    billing = Table("billing", [
        Column("billid", "int", False),
        Column("appointmentid", "int"),
        Column("amount", "dec(10,2)"),
        Column("paymentmethod", "varchar(20)"),
        Column("status", "varchar(20)"),
        Column("dateissued", "date"),
        Column("datepaid", "date"),
    ], pk=("billid",), fks=[(("appointmentid",), "appointments", ("appointmentid",))])
    billing.rows = (rows_from(sql, "billing", billing.colnames())
                    + read_csv(csv_dir / "Billing.csv", billing.colnames()))

    labreferrals = Table("labreferrals", [
        Column("labreferralid", "int", False),
        Column("appointmentid", "int"),
        Column("testtype", "varchar(100)"),
        Column("testdate", "date"),
        Column("result", "text"),
        Column("status", "varchar(20)"),
    ], pk=("labreferralid",), fks=[(("appointmentid",), "appointments", ("appointmentid",))])
    labreferrals.rows = (rows_from(sql, "labreferrals", labreferrals.colnames())
                         + read_csv(csv_dir / "LabReferrals.csv", labreferrals.colnames()))

    allergies = Table("allergies", [
        Column("allergyid", "int", False),
        Column("patientid", "int", False),
        Column("allergy", "varchar(100)"),
    ], pk=("allergyid",), fks=[(("patientid",), "patients", ("patientid",))])
    al = (rows_from(sql, "allergies", ["patientid", "allergies"])
          + read_csv(csv_dir / "Allergies.csv", ["patientid", "allergy"],
                     rename={"allergy": "allergy"}))
    allergies.rows = [[i] + r for i, r in enumerate(al, 1)]

    # "UPDATE departments SET HeadOfDepartment = …" trailer in the source file.
    heads = {1: 1, 2: 2, 3: 3, 4: 4, 5: 7, 6: 12, 7: 17, 8: 22, 9: 25, 10: 28, 12: 33}
    hod = departments.index("headofdepartment")
    for r in departments.rows:
        if r[0] in heads:
            r[hod] = heads[r[0]]

    return Dataset(
        "healthcare", "Healthcare",
        [departments, medicalstaff, nonmedicalstaff, patients, appointments,
         prescriptions, medicalrecords, billing, labreferrals, allergies],
        "Medical clinic — patients, staff, appointments, prescriptions, labs and billing",
    )


# ─── Driver ──────────────────────────────────────────────────────────────────

BUILDERS = {
    "booking": build_booking,
    "bookstore": build_bookstore,
    "healthcare": build_healthcare,
}


def main(argv: list[str]) -> int:
    wanted = argv[1:] or list(BUILDERS)
    unknown = [w for w in wanted if w not in BUILDERS]
    if unknown:
        print(f"unknown dataset(s): {', '.join(unknown)}", file=sys.stderr)
        print(f"known: {', '.join(BUILDERS)}", file=sys.stderr)
        return 2

    for name in wanted:
        print(f"\n=== {name} ===")
        ds = BUILDERS[name]()
        enforce_fks(ds)

        for t in ds.tables:
            print(f"    {t.name:<20} {len(t.rows):>8,} rows")
        total = sum(len(t.rows) for t in ds.tables)
        print(f"    {'TOTAL':<20} {total:>8,} rows in {len(ds.tables)} tables")

        for dialect in DIALECTS:
            subdir, fname = OUTPUT[dialect]
            out = ROOT / subdir.format(ds=name) / fname.format(ds=name)
            out.parent.mkdir(parents=True, exist_ok=True)
            text = build_file(ds, dialect)
            out.write_text(text, encoding="utf-8", newline="\n")
            print(f"      → {out.relative_to(ROOT)}  ({len(text) / 1e6:.1f} MB)")

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
