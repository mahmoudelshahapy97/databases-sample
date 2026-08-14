# =============================================================================
# Oracle XE 21c — Custom image
# Extends gvenzl/oracle-xe with init scripts baked in and made executable.
# Source SQL/CSV files (oracle/data) are mounted at runtime at /source.
# =============================================================================
FROM gvenzl/oracle-xe:21-slim-faststart

USER root

# Nothing goes into /container-entrypoint-initdb.d: the gvenzl entrypoint runs
# every .sh and .sql found there itself, on the start that creates the database,
# and entrypoint.sh drives the same scripts — so anything placed there is loaded
# twice, concurrently, and the two passes drop each other's users mid-load.
# entrypoint.sh is the single driver; the scripts and the SQL assets they
# @-call both live under /opt/seed.
COPY init/   /opt/seed/init/
COPY assets/ /opt/seed/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /opt/seed/init/*.sh /entrypoint.sh \
 && chmod -R a+rX /opt/seed

USER oracle

ENTRYPOINT ["/entrypoint.sh"]

