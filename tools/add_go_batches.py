#!/usr/bin/env python3
"""
add_go_batches.py
Adds a GO statement between consecutive hotel_bookings INSERT batches so that
SQL Server doesn't run out of memory trying to plan one enormous batch.
"""
import sys, shutil, os

src = "/mnt/c/Users/User/Desktop/text-to-sql-multi-tenant/databases/sqlserver/data/booking/booking_mssql.sql"
tmp = src + ".tmp"

INSERT_HEADER = "INSERT INTO [booking].[hotel_bookings]"

with open(src, "r", encoding="utf-8") as f:
    lines = f.readlines()

out = []
added = 0
for i, line in enumerate(lines):
    out.append(line)
    stripped = line.rstrip()
    if stripped.endswith(";") and (i + 1) < len(lines):
        next_line = lines[i + 1].lstrip()
        if next_line.startswith(INSERT_HEADER):
            out.append("GO\n")
            added += 1

with open(tmp, "w", encoding="utf-8", newline="") as f:
    f.writelines(out)

shutil.move(tmp, src)
print(f"Done. Added {added} GO statements between hotel_bookings INSERT batches.")
total_go = sum(1 for l in out if l.strip() == "GO")
print(f"Total GO statements in file: {total_go}")
