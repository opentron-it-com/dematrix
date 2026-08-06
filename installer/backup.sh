#!/bin/sh
set -e

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups"
BACKUP_FILE="${BACKUP_DIR}/docdb_backup_${TIMESTAMP}.sql.gz"

echo "Starting database backup at ${TIMESTAMP}..."
mkdir -p "${BACKUP_DIR}"

PGPASSWORD="${DB_PASSWORD}" pg_dump -h postgres -U docuser -d docdb | gzip > "${BACKUP_FILE}"

echo "Backup completed successfully: ${BACKUP_FILE}"

# Keep only the last 7 daily backups
find "${BACKUP_DIR}" -type f -name "docdb_backup_*.sql.gz" -mtime +7 -delete