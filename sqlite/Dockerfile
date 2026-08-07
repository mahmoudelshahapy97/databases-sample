# =============================================================================
# SQLite — Datasette web UI
# Alpine-based image with sqlite3 + datasette installed.
# Builds .db files from SQL sources on first start, then serves them
# via Datasette at http://localhost:8001
# =============================================================================
FROM python:3.12-alpine

# Install sqlite3 CLI
RUN apk add --no-cache sqlite

# Install datasette (lightweight SQLite web explorer)
RUN pip install --no-cache-dir datasette

# Create data directory
RUN mkdir -p /data /init

# Copy init script and menagerie SQL
COPY entrypoint.sh /entrypoint.sh
COPY init/         /init/

RUN chmod +x /entrypoint.sh

EXPOSE 8001

ENTRYPOINT ["/entrypoint.sh"]
