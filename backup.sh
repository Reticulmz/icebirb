# Load settings
SYNC_REPLAYS=$(awk -F "=" '/sync_replays/ {print $2}' config.ini)
SYNC_AVATARS=$(awk -F "=" '/sync_avatars/ {print $2}' config.ini)
SYNC_SCREENSHOTS=$(awk -F "=" '/sync_screenshots/ {print $2}' config.ini)
SYNC_DATABASE=$(awk -F "=" '/sync_database/ {print $2}' config.ini)

DB_USERNAME=$(awk -F "=" '/db_username/ {print $2}' config.ini)
DB_PASSWORD=$(awk -F "=" '/db_password/ {print $2}' config.ini)
DB_NAME=$(awk -F "=" '/db_name/ {print $2}' config.ini)

REPLAYS_FOLDER=$(awk -F "=" '/replays_folder/ {print $2}' config.ini)
AVATARS_FOLDER=$(awk -F "=" '/avatars_folder/ {print $2}' config.ini)
SCREENSHOTS_FOLDER=$(awk -F "=" '/screenshots_folder/ {print $2}' config.ini)

BACKBLAZE_BUCKET_NAME=$(awk -F "=" '/backblaze_bucket_name/ {print $2}' config.ini)
BACKBLAZE_ACCOUNT_ID=$(awk -F "=" '/backblaze_account_id/ {print $2}' config.ini)
BACKBLAZE_APPLICATION_KEY=$(awk -F "=" '/backblaze_application_key/ {print $2}' config.ini)

S3_BUCKET_NAME=$(awk -F "=" '/s3_bucket_name/ {print $2}' config.ini)

LOCAL_FOLDER=$(awk -F "=" '/local_folder/ {print $2}' config.ini)

RSYNC_REMOTE=$(awk -F "=" '/rsync_remote/ {print $2}' config.ini)

SCHIAVO_URL=$(awk -F "=" '/schiavo_url/ {print $2}' config.ini)

BLUE='\033[0;36m'
NC='\033[0m'

# Variables
WHEN=$(date '+%F--%H-%M-%S')

# First, let's create a directory, cd to it and empty it
printf "$BLUE==> Creating temp directory...$NC"
mkdir temp
cd temp
rm -rf *

# Database backup
if [ $SYNC_DATABASE = true ]; then
	printf "$BLUE==> Dumping database...$NC"
	mkdir db
	mysqldump -u "$DB_USERNAME" "-p$DB_PASSWORD" "$DB_NAME" > "db/db-$WHEN.sql"
fi

# Replays backup
if [ $SYNC_REPLAYS = true ]; then
	printf "$BLUE==> Copying replays...$NC"
	rsync -r "$REPLAYS_FOLDER" replays
fi

# Avatars backup
if [ $SYNC_AVATARS = true ]; then
	printf "$BLUE==> Copying avatars...$NC"
	rsync -r "$AVATARS_FOLDER" avatars
fi

# Done, let's tar this
printf "$BLUE==> Creating backup archive...$NC"
tar -cf "backup-$WHEN.tar.gz" *

# Update latest backup
printf "Latest backup: $WHEN" > latest-backup.txt

# Upload backup to backblaze
if [ -z != $BACKBLAZE_BUCKET_NAME ]; then
	b2 authorize_account "$BACKBLAZE_ACCOUNT_ID" "$BACKBLAZE_APPLICATION_KEY"
	printf "$BLUE==> Uploading backup archive to Backblaze...$NC"
	b2 upload_file "$BACKBLAZE_BUCKET_NAME" "backup-$WHEN.tar.gz" "backup-$WHEN.tar.gz"
fi

# Upload backup to S3
if [ -z != $S3_BUCKET_NAME ]; then
	printf "$BLUE==> Uploading backup archive to AWS S3...$NC"
	aws s3 cp "backup-$WHEN.tar.gz" "$S3_BUCKET_NAME"
fi

# Copy backup to local folder
if [ -z != $LOCAL_FOLDER ]; then
	printf "$BLUE==> Copying backup to local folder...$NC"
	cp "backup-$WHEN.tar.gz" "$LOCAL_FOLDER/"
fi

# Send backup to remote server
if [ -z != $RSYNC_REMOTE ]; then
	printf "$BLUE==> Sending backup to backup server...$NC"
	rsync -aRP "backup-$WHEN.tar.gz" "$RSYNC_REMOTE/full_backups/"
	rsync -a latest-backup.txt "$RSYNC_REMOTE"
fi


# Schiavo message
if [ -z != $SCHIAVO_URL ]; then
	curl --data-urlencode "message=**icebirb** Full ripple backup completed! Size: $(du -BM backup-$WHEN.tar.gz | cut -f1)" "$SCHIAVO_URL/bunk" 2>&1 > /dev/null
fi

# Exit temp folder
cd ..

# Delete temp folder
printf "$BLUE==> Deleting temp files...$NC"
rm -rf temp
printf "$BLUE==> Backup complete!$NC"
