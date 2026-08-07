# =============================================================================
# SQL Server 2022 — Custom image
# Extends the official image with an entrypoint that waits for SQL Server
# to be ready before executing seed SQL files.
# =============================================================================
FROM mcr.microsoft.com/mssql/server:2022-latest

USER root

# dos2unix handles CRLF line endings if the entrypoint was edited on Windows
RUN apt-get update \
 && apt-get install -y --no-install-recommends dos2unix \
 && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN dos2unix /entrypoint.sh && chmod +x /entrypoint.sh

USER mssql

ENTRYPOINT ["/entrypoint.sh"]
