#!/bin/bash

# ========================== Declare Infor ==========================
BACKUPDIR="/backups/File"
APACHELOGDIRECTORY="/var/log/httpd"
APACHELOGNAME="COHOMES-APACHE-LOGS"
APACHEBACKUPDIR="/backups/apacheLog"
SYSLOGDIRECTORY="/var/log"
SYSLOGNAME="COHOMES-SYSLOG"
SYSBACKUPDIR="/backups/sysLog"
#SCNAME="COHOMES"
DM=$(date +%Y%m%d-%H_%M_%S)
DB_USER="backup"
DB_HOST="vsp-cohomes-prod-db.cxs8cc846gxq.ap-southeast-1.rds.amazonaws.com"
# ========================== Declare Path Source ==========================
COHOMES_SRC="/var/www/html/"

# ========================== Declare Tools Path ==========================
DUMP="/usr/bin/mysqldump"
ZIP="/usr/bin/zip"
REMOVE="/bin/rm"
FIND="/usr/bin/find"
MYSQL="/usr/bin/mysql"
AWS="/usr/bin/aws"
# ========================== Ensure env vars are available ==========================
if [[ -z "$MYSQL_PASS" || -z "$ZIP_PASS" ]]; then
    echo "[ERROR] MYSQL_PASS or ZIP_PASS not set in environment."
    exit 1
fi

# ========================== BACKUP DATABASE ==========================
ExcludeDatabases="Database|information_schema|performance_schema|mysql|sys"

databases=$($MYSQL -h"$DB_HOST" -u"$DB_USER" -p"$MYSQL_PASS" -e "SHOW DATABASES;" | tr -d "| " | egrep -v "$ExcludeDatabases")

for db in $databases; do
    echo "Dumping database: $db"
    $DUMP --single-transaction --set-gtid-purged=OFF -h"$DB_HOST" -u"$DB_USER" -p"$MYSQL_PASS" --databases "$db" > "$BACKUPDIR/$db-$DM.sql"
    $ZIP -r -P "$ZIP_PASS" "$BACKUPDIR/$db-$DM.sql.zip" "$BACKUPDIR/$db-$DM.sql"
    $REMOVE -f "$BACKUPDIR/$db-$DM.sql"
done

# ========================== BACKUP SOURCE ==========================
for s in $($FIND "$COHOMES_SRC" -maxdepth 1 -mindepth 1 -type d ! -name "coming_soon"); do
    echo "Backup source: $s"
    $ZIP -r -P "$ZIP_PASS" "$BACKUPDIR/$(basename "$s")-$DM.zip" "$s"
done

# ========================== BACKUP APACHE LOG ==========================
$FIND "$APACHEBACKUPDIR" -type f -mtime +6 | xargs -r $REMOVE -f
$ZIP -r -P "$ZIP_PASS" "$APACHEBACKUPDIR/$APACHELOGNAME-$DM.zip" "$APACHELOGDIRECTORY" && \
$REMOVE -f "$APACHELOGDIRECTORY"/*
systemctl reload httpd

# ========================== BACKUP SYSTEMS LOG ==========================
$FIND "$SYSBACKUPDIR" -type f -mtime +6 | xargs -r $REMOVE -f
$ZIP -r -P "$ZIP_PASS" "$SYSBACKUPDIR/$SYSLOGNAME-$DM.zip" "$SYSLOGDIRECTORY" --exclude "$APACHELOGDIRECTORY/*" && \
truncate -s 0 "$SYSLOGDIRECTORY"/*

# ========================== CLEAN UP OLD BACKUPS ==========================
$FIND "$BACKUPDIR" -type f -mtime +5 | xargs -r $REMOVE -f
$FIND "$APACHEBACKUPDIR" -type f -mtime +5 | xargs -r $REMOVE -f
$FIND "$SYSBACKUPDIR" -type f -mtime +5 | xargs -r $REMOVE -f

# ========================== Sync Source to S3 Bucket ==========================
$AWS s3 sync "$BACKUPDIR" s3://prod-cohomes/backups/
