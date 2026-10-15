#!/bin/sh
# PostgreSQL zaxirasi (T-092). `pg_dump -Fc` — siqilgan, `pg_restore` bilan tiklanadi.
#   sh backup.sh once   — bitta zaxira
#   sh backup.sh loop   — har BACKUP_INTERVAL_SECONDS (standart 86400) da, eskisi o'chadi
# Muhit: PGHOST, PGUSER, PGPASSWORD, PGDATABASE, BACKUP_KEEP_DAYS (standart 14).
set -eu

DIR=/backups
KEEP_DAYS="${BACKUP_KEEP_DAYS:-14}"

backup() {
	stamp=$(date -u +%Y%m%d-%H%M)
	tmp="$DIR/.pos-$stamp.dump.tmp"
	out="$DIR/pos-$stamp.dump"
	pg_dump -Fc -f "$tmp"
	# Butunligini tekshirish: arxiv o'qilmasa — zaxira yo'q deb hisoblanadi.
	pg_restore --list "$tmp" >/dev/null
	mv "$tmp" "$out"
	# Tovar rasmlari (T-105): /media bo'lsa — alohida arxiv.
	if [ -d /media ]; then
		mtmp="$DIR/.media-$stamp.tar.gz.tmp"
		tar -czf "$mtmp" -C /media .
		mv "$mtmp" "$DIR/media-$stamp.tar.gz"
	fi
	find "$DIR" \( -name 'pos-*.dump' -o -name 'media-*.tar.gz' \) -mtime +"$KEEP_DAYS" -delete
	echo "backup ok: $out ($(du -h "$out" | cut -f1))"
}

mkdir -p "$DIR"
case "${1:-once}" in
	once) backup ;;
	loop)
		while true; do
			backup || echo "backup FAILED $(date -u)" >&2
			sleep "${BACKUP_INTERVAL_SECONDS:-86400}"
		done
		;;
	*) echo "usage: backup.sh once|loop" >&2; exit 2 ;;
esac
