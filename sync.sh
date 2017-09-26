# Load settings
SYNC_REPLAYS=$(awk -F "=" '/do_sync_replays/ {print $2}' config.ini)
SYNC_AVATARS=$(awk -F "=" '/do_sync_avatars/ {print $2}' config.ini)
SYNC_SCREENSHOTS=$(awk -F "=" '/do_sync_screenshots/ {print $2}' config.ini)
SYNC_PROFILE_BACKGROUNDS=$(awk -F "=" '/do_sync_profile_backgrounds/ {print $2}' config.ini)
SYNC_DATABASE=$(awk -F "=" '/do_sync_database/ {print $2}' config.ini)

DB_USERNAME=$(awk -F "=" '/db_username/ {print $2}' config.ini)
DB_PASSWORD=$(awk -F "=" '/db_password/ {print $2}' config.ini)
DB_NAME=$(awk -F "=" '/db_name/ {print $2}' config.ini)

REPLAYS_FOLDER=$(awk -F "=" '/replays_folder/ {print $2}' config.ini)
AVATARS_FOLDER=$(awk -F "=" '/avatars_folder/ {print $2}' config.ini)
SCREENSHOTS_FOLDER=$(awk -F "=" '/screenshots_folder/ {print $2}' config.ini)
PROFILE_BACKGROUNDS_FOLDER=$(awk -F "=" '/profile_backgrounds_folder/ {print $2}' config.ini)

RSYNC_REMOTE=$(awk -F "=" '/sync_rsync_remote/ {print $2}' config.ini)
RSYNC_PORT=$(awk -F "=" '/sync_rsync_port/ {print $2}' config.ini)

SYNC_MTIME=$(awk -F "=" '/sync_mtime/ {print $2}' config.ini)

SCHIAVO_URL=$(awk -F "=" '/schiavo_url/ {print $2}' config.ini)

BLUE='\033[0;36m'
NC='\033[0m'

# Sync replays
if [ $SYNC_REPLAYS = true ]; then
	printf "$BLUE==> Syncing replays...$NC\n"
	if [ $SYNC_MTIME -lt 0 ]; then
		# Classic sync. Send all files that are not present on sync server.
		# Use when all replays are saved in the sync storage (classic server)
		printf "$BLUE(classic sync)$NC\n"
		rsync -e "ssh -p $RSYNC_PORT" -azvP "$REPLAYS_FOLDER" "$RSYNC_REMOTE"
	else
		# New-files-only sync. Send all files that have been modified in the last $SYNC_MTIME*24 hours
		# Use if not all replays are saved in the sync storage (eg: C14, where files older than
		# 7 days are automatically moved to the safe storage and removed from the rsync folder)
		printf "$BLUE(new-files-only sync)$NC\n"
		find "$REPLAYS_FOLDER" -mtime "$SYNC_MTIME" -print0 | rsync -e "ssh -p $RSYNC_PORT" -azvP0 "$REPLAYS_FOLDER" "$RSYNC_REMOTE"
	fi
fi

# Sync avatars
if [ $SYNC_AVATARS = true ]; then
	printf "\n$BLUE==> Syncing avatars...$NC\n"
	rsync -e "ssh -p $RSYNC_PORT" -azvP "$AVATARS_FOLDER" "$RSYNC_REMOTE"
fi

# Sync screenshots
if [ $SYNC_SCREENSHOTS = true ]; then
	printf "\n$BLUE==> Syncing screenshots...$NC\n"
	rsync -e "ssh -p $RSYNC_PORT" -azvP "$SCREENSHOTS_FOLDER" "$RSYNC_REMOTE"
fi

# Sync profile backgrounds
if [ $SYNC_PROFILE_BACKGROUNDS = true ]; then
	printf "\n$BLUE==> Syncing profile backgrounds...$NC\n"
	rsync -e "ssh -p $RSYNC_PORT" -azvP "$PROFILE_BACKGROUNDS_FOLDER" "$RSYNC_REMOTE"
fi

# Dump and sync database
if [ $SYNC_DATABASE = true ]; then
	printf "\n$BLUE==> Dumping database...$NC\n"
	mysqldump -u "$DB_USERNAME" "-p$DB_PASSWORD" "$DB_NAME" > "db.sql"

	printf "\n$BLUE==> Syncing database...$NC\n"
	rsync -e "ssh -p $RSYNC_PORT" -azvP db.sql "$RSYNC_REMOTE"

	printf "\n$BLUE==> Removing temp database...$NC"
	rm -rf db.sql
fi

# Update latest sync
echo "Latest sync: $(date '+%F %H:%M:%S')\n" > latest-sync.txt
rsync -e "ssh -p $RSYNC_PORT" -a latest-sync.txt "$RSYNC_REMOTE"

# Schiavo message
if [ -z != $SCHIAVO_URL ]; then
	curl --data-urlencode "message=**icebirb** Ripple data sync completed!" "$SCHIAVO_URL/bunk" 2>&1 > /dev/null
fi

printf "\n$BLUE==> Done!$NC\n"