#!/bin/sh
# Nightly pg_dump to the backup disk, keeps 14 days (ADR-028)
set -eu
cd "$(dirname "$0")"
. ./.env
out="/srv/backups/packrat-$(date +%F).dump"
# write to .tmp first so a failed dump never replaces a good one
docker compose exec -T postgres pg_dump -U "$POSTGRES_USER" -Fc "$POSTGRES_DB" > "$out.tmp"
mv "$out.tmp" "$out"
find /srv/backups -name 'packrat-*.dump' -mtime +14 -delete
