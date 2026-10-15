#!/bin/sh
# Zaxiradan tiklash (T-092). DIQQAT: joriy baza ma'lumotlari ALMASHTIRILADI.
#   docker compose -f docker-compose.prod.yml --env-file .env.prod stop backend scheduler admin
#   docker compose -f docker-compose.prod.yml --env-file .env.prod run --rm \
#     --entrypoint sh backup /deploy/restore.sh /backups/pos-YYYYMMDD-HHMM.dump
#   docker compose -f docker-compose.prod.yml --env-file .env.prod up -d
set -eu

file="${1:?zaxira fayli: /backups/pos-....dump}"
# Ixtiyoriy 2-argument: rasmlar arxivi /backups/media-....tar.gz (T-105).
media="${2:-}"
[ -f "$file" ] || { echo "topilmadi: $file" >&2; exit 2; }
pg_restore --list "$file" >/dev/null

echo "tiklanmoqda: $file -> $PGDATABASE"
pg_restore --clean --if-exists --no-owner --exit-on-error -d "$PGDATABASE" "$file"
echo "restore ok: $(psql -tAc 'SELECT count(*) FROM django_migrations') migratsiya qatori"
if [ -n "$media" ]; then
	[ -f "$media" ] || { echo "topilmadi: $media" >&2; exit 2; }
	tar -xzf "$media" -C /media
	echo "media restore ok: $media"
fi
