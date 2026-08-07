# =============================================================================
# Oracle XE 21c — Custom image
# Extends gvenzl/oracle-xe with init scripts baked in and made executable.
# Source SQL/CSV files (oracle/data) are mounted at runtime at /source.
# =============================================================================
FROM gvenzl/oracle-xe:21-slim-faststart

USER root

# Only the numbered shell scripts belong in the init hook — the gvenzl
# entrypoint executes *every* .sh and .sql it finds there, so SQL assets that
# are meant to be @-called by those scripts live in /opt/seed instead.
COPY init/   /container-entrypoint-initdb.d/
COPY assets/ /opt/seed/
RUN chmod +x /container-entrypoint-initdb.d/*.sh \
 && chmod -R a+rX /opt/seed

USER oracle
