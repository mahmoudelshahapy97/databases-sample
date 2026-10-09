#!/usr/bin/env bash
# Runs ON THE DEPLOY HOST, from $DEPLOY_PATH. Uploaded and invoked by
# .github/workflows/deploy.yml; not meant to be run from a laptop.
#
#   deploy.sh <sqlserver-image> <oracle-image> <sqlite-image> <dockerhub-user>
#
# The Docker Hub token arrives on stdin rather than as an argument, so it never
# appears in the host's process list.
#
# What the host must already have:
#   - $DEPLOY_PATH/.env      MSSQL_PASSWORD, ORACLE_PASSWORD, POSTGRES_PASSWORD, ...
#                            CI never sees these; this script refuses to run without it.
#   - Docker Compose v2.17+  for repeated --env-file and --wait-timeout.
#   - rsync                  the workflow uses it to sync the bind-mounted seed data.
#
# Volumes are never touched. Seeding only happens on an empty volume, so a first
# deploy takes as long as the slowest engine (Oracle SH: tens of minutes).

set -euo pipefail

SQLSERVER_IMAGE=$1
ORACLE_IMAGE=$2
SQLITE_IMAGE=$3
HUB_USER=$4

log() { echo "==> $*"; }

dc() {
  docker compose --env-file .env --env-file release.env \
    -f docker-compose.yml -f docker-compose.prod.yml "$@"
}

if [ ! -f .env ]; then
  echo "ERROR: $(pwd)/.env is missing. Create it with the database passwords before the first deploy." >&2
  exit 1
fi

# Pull before touching anything, so a registry outage or a bad tag fails the deploy
# with the running stack untouched. Logged out again straight after.
log "Pulling images"
docker login --username "$HUB_USER" --password-stdin >/dev/null
trap 'docker logout >/dev/null 2>&1 || true' EXIT
for image in "$SQLSERVER_IMAGE" "$ORACLE_IMAGE" "$SQLITE_IMAGE"; do
  docker pull --quiet "$image"
done
docker logout >/dev/null 2>&1 || true

if [ -f release.env ]; then
  cp release.env .deploy/release.env.previous
fi
cat > release.env <<EOT
MULTIDB_SQLSERVER_IMAGE=$SQLSERVER_IMAGE
MULTIDB_ORACLE_IMAGE=$ORACLE_IMAGE
MULTIDB_SQLITE_IMAGE=$SQLITE_IMAGE
EOT

log "Starting the stack"
if ! dc up -d --no-build --remove-orphans --wait --wait-timeout 3600; then
  echo "ERROR: the stack did not become healthy." >&2
  dc ps || true
  dc logs --tail 50 || true
  exit 1
fi

# Keep the current and previous release of each image, nothing older.
keep=$(cat release.env .deploy/release.env.previous 2>/dev/null | cut -d= -f2 | sort -u)
for image in "$SQLSERVER_IMAGE" "$ORACLE_IMAGE" "$SQLITE_IMAGE"; do
  repo=${image%:*}
  docker image ls "$repo" --format '{{.Repository}}:{{.Tag}}' | while read -r ref; do
    grep -qxF "$ref" <<<"$keep" || docker image rm "$ref" >/dev/null 2>&1 || true
  done
done
docker image prune -f >/dev/null

log "Deployed"
