## Icebirb

- Origin: https://git.zxq.co/ripple/icebirb
- Mirror: https://github.com/osuripple/icebirb

### Sync & Backup Ripple replays, screenshots, avatars and database
This simple set of bash scripts can sync Ripple replays, screenshots, avatars and database between different servers, so they're safe in case the main server explodes.
- `sync.sh` syncs Ripple's data to another server. Only new or edited files get synced to the backup server.
- `backup.sh` copies all data in a .tar.gz file, sends it to the backup server and, optionally, upload them to Backblaze and/or AWS S3.

We recommend running `sync.sh` every 2 hours or so, and `backup.sh` every week/month, depending on how large your ripple instance is.

## Requirements
- Two linux servers with rsync
- Backblaze B2 CLI Tool (optional)
- AWS CLI (optional)

## Configuration
Copy `config.sample.ini` as `config.ini` and edit it. Main options:
- `sync_*`: `sync.sh` and `backup.sh` will sync/copy that data
- `db_*`: MySQL credentials
- `*_folder`: Folders containing ripple data
- `backblaze_*`: Backblaze credentials. Optional. Leave everything empty to disable Backblaze upload
- `aws_*`: AWS S3 credentials. Optional. Leave everything empty to disable S3 upload
- `local_folder`: If not empty, all backups will be copied in that local folder. Optional. Leave empty to disable.
- `rsync_remote`: Backup server's rsync address. Used to sync data and send backups.
- `schiavo_url`: Schiavo main URL. Optional. Leave empty to disable. Since schiavo is closed yource, you should keep this key empty.

## License
All code in this repository is licensed under the GNU AGPL 3 License.  
See the "LICENSE" file for more information  