# Folder Backup Script
This is a Bash script designed to perform automated backups of system folders, featuring Telegram notifications and backup rotation.

## The Idea Behind this Script
It emerged from the need to have a safe and automated way to backup important system folders while maintaining a controlled backup history and process status notifications.

## Main Features
- Sends Telegram notifications (messages and log files)
- Uses `tar` to generate and compress backups
- Supports multiple folder groups
- Configurable `maxBackups` variable for each folder group
- Automatic rotation of old backups
- Detailed logging system
- Real-time status notifications

# How to Use

## How to Download/Update the Script
```shell
wget -O folder-backups.sh https://path-to-script/folder-backups.sh && chmod +x folder-backups.sh
```

## In the Terminal
```shell
bash folder-backups.sh config.json
```
Where:
- `folder-backups.sh` is the script
- `config.json` is the configuration file

## Cron Job Example
You can use `crontab` to schedule the script execution.
- Recommendation: use `root` crontab to prevent permission issues:
```shell
sudo crontab -e
```
Then add this line (adjust folder paths):
```shell
# folder-backups
5 0 * * 1  /path/to/script/folder-backups.sh /path/to/script/config.json > /path/to/script/weekly_backup.log 2>&1
```

## How to Configure the config.json File
```json
{
    "config": {
        "BackupDestination": "/path/to/backup/destination",
        "LogDestination": "/path/to/logs"
    },
    "telegram": {
        "ChatID": "your-chat-id",
        "APIkey": "your-api-key"
    },
    "folders": [
        {
            "name": "personal_docs",
            "maxBackups": 5,
            "paths": [
                "/home/user/Documents",
                "/home/user/Pictures"
            ]
        },
        {
            "name": "projects",
            "maxBackups": 3,
            "paths": [
                "/home/user/Projects"
            ]
        }
    ]
}
```

### Configuration Parameters

| Parameter | Value | Description |
|---------------------- | -----------| ---------------------------------|
| config.BackupDestination | path | Destination for `*.tar.gz` files. **The script will create a subfolder for each group!** |
| config.LogDestination | path | Destination for log files |
| telegram.ChatID | Number | Telegram chat/group identifier (you can get this by adding `@getmyid_bot` to your chat/group) |
| telegram.APIkey | Text | Telegram Bot API Key |
| folders.name | text | Name of the folder group to backup |
| folders.maxBackups | number | Specifies how many backups to keep (when this value is reached, the oldest backup is deleted) |
| folders.paths | array | Array of folder paths to backup |

# Folder Structure
The script will create the following structure:
```
backup_destination/
├── personal_docs/
│   ├── personal_docs_20240103_120000.tar.gz
│   ├── personal_docs_20240102_120000.tar.gz
│   └── personal_docs_20240101_120000.tar.gz
└── projects/
    ├── projects_20240103_120000.tar.gz
    └── projects_20240102_120000.tar.gz
```

# Log Format
The script generates detailed logs with t