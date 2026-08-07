import sys

src_path = sys.argv[1]
dst_path = sys.argv[2]

BATCH_SIZE = 100

with open(src_path, 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

out = []
header = None
batch = []


def flush_batch():
    global batch
    if not batch:
        return
    out.append("INSERT ALL\n")
    for into_clause, val in batch:
        out.append(f"  {into_clause} VALUES {val}\n")
    out.append("SELECT 1 FROM DUAL;\n")
    out.append("COMMIT;\n")
    batch = []


for line in lines:
    stripped = line.strip()
    if stripped.startswith("GRANT ") or stripped.startswith("CONNECT "):
        continue

    if stripped.startswith("INSERT INTO ") and " VALUES" in stripped:
        header = stripped.split(" VALUES")[0]
        continue

    if header:
        if stripped.startswith("("):
            # Extract row values, batch them into Oracle's INSERT ALL form
            is_last = stripped.endswith(";")
            val = stripped.rstrip(",;").strip()
            into_clause = "INTO " + header[len("INSERT INTO "):]
            batch.append((into_clause, val))
            if len(batch) >= BATCH_SIZE:
                flush_batch()
            if is_last:
                flush_batch()
                header = None
            continue
        elif stripped == "":
            flush_batch()
            header = None
            out.append("\n")
            continue

    out.append(line)

flush_batch()

with open(dst_path, 'w', encoding='utf-8') as f:
    f.writelines(out)

print("Conversion complete.")
