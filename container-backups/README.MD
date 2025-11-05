## The Idea behind this Script
I needed a way to backup my Docker volumes in a safe way, and with minimal downtime.

# CONTAINER BACKUP Script v2.1.0

## Main Features
- Backs up Docker volumes **by stack/compose** (not by individual container)
- **Stops the entire stack** using `docker compose down` before backup, and **starts it again** with `docker compose up -d` after backup
- **Backups are compressed** as `.tar.gz` archives
- Rotates backups per volume, configurable with `maxBackups`
- **Backs up the entire folder containing the compose file** (`composeFile`), not just the file itself
- **Rotates backups of the compose folder** using the `maxBackups` value of the first volume in the stack
- **Shows/logs the size of each backup and the total size per stack**
- **Supports per-volume delay before backup** using the `preBackupSleep` parameter (useful for database flushes or app shutdowns)
- Sends Telegram notifications (messages and log files), including support for threads (`MessageThreadID`)
- All logs are saved and sent via Telegram at the end of the process
- Error handling: errors are counted and reported in the final Telegram notification

## Important Notice

> **Warning:** The script stops and starts each stack using `docker compose down` and `docker compose up -d`. This will cause downtime for all services in the stack during the backup process.

## How it works

1. For each stack defined in `config.json`:
    - The script stops the stack with `docker compose -f <composeFile> down`
    - For each volume:
        - If `preBackupSleep` is set, waits the specified seconds before backup
        - Backs up and **compresses** the volume as a `.tar.gz` file
    - Backs up and compresses the **entire folder containing the compose file** as `compose_dir_<timestamp>.tar.gz`
    - Rotates old backups according to `maxBackups` (for both volumes and compose folder; compose folder uses the first volume's `maxBackups`)
    - Shows/logs the size of each backup and the total size per stack
    - Starts the stack again with `docker compose -f <composeFile> up -d`
    - If any step fails, it logs the error and notifies via Telegram, then continues with the next stack

2. If a stack is missing `composeFile`, it logs an error and skips to the next stack.

## Telegram Notifications

- The script sends notifications to the configured Telegram chat/group.
- Example notification:
  ```
  *HOST-1* / *Docker Backup Notification*
  ✅ Backup completed for stack: `stack1`
  Backup file: `/mnt/backups/stack1/volume1/volume1_250902-1900.tar.gz` (Size: 2.1M)
  Compose folder backup: `/mnt/backups/stack1/compose_dir/compose_dir_250902-1900.tar.gz` (Size: 1.2K)
  Total backup size for stack 'stack1': 3.3M
  ```
- If an error occurs (e.g., cannot stop/start stack, backup fails), a warning is sent.

![telegram notification](https://github.com/MrCaringi/assets/blob/main/images/scripts/container-backups/telegram-messages.jpg)

## config.json format

```json
{
    "config": {
        "BackupDestination": "/path/to/backup/destination"
    },
    "telegram": {
        "ChatID": "your-chat-id",
        "APIkey": "your-api-key",
        "MessageThreadID": "123"
    },
    "stacks": [
        {
            "name": "stack1",
            "composeFile": "/path/to/compose.yml",
            "volumes": [
                {
                    "path": "/path/to/volume1",
                    "maxBackups": 5,
                    "preBackupSleep": 10
                },
                {
                    "path": "/path/to/volume2",
                    "maxBackups": 3
                }
            ]
        }
    ]
}
```

## Requirements

- `docker compose` (plugin)
- `jq`
- `tar`

# How to use

## How to update/download the script
```shell
wget -O container-backups.sh https://raw.githubusercontent.com/MrCaringi/Backups-and-Replication/master/container-backups/container-backups.sh && chmod +x container-backups.sh
```

## In the Terminal
```shell
bash container-backups.sh config.json
```
Where:
- `container-backups.sh` is the script
- `config.json` is your configuration file

![Terminal Output](https://github.com/MrCaringi/assets/blob/main/images/scripts/container-backups/terminal.png)

## Cron Job Example
You can use `crontab` to schedule this script.
- **Recommendation:** use root's crontab to prevent permission issues:
```shell
sudo crontab -e
```
Then add this line (adjust folder paths):
```shell
# container-backups
5 0 * * 1  /folder/location-of-script/container-backups/container-backups.sh /folder/location-of-script/container-backups/config.json > /folder/location-of-script/container-backups/backup.log 2>&1
```
## How to configure config.json
| Parameter                       | Value         | Description                                                                                   |
|----------------------------------|--------------|-----------------------------------------------------------------------------------------------|
| config.BackupDestination         | file path    | Destination for the `*.tar.gz` files. The script creates a subfolder for every stack.         |
| telegram.ChatID                  | Number       | Telegram Chat/Group ID (get it by adding `@getmyid_bot` to your chat/group)                   |
| telegram.APIkey                  | Text         | Telegram Bot API Key                                                                          |
| telegram.MessageThreadID         | Number       | *(Optional)* Telegram thread ID for sending messages to a specific topic in groups            |
| stacks.name                      | Text         | Name of your stack (should match `container_name` in your `docker-compose.yml`)               |
| stacks.composeFile               | File path    | Path to the docker-compose file to backup                                                     |
| stacks.volumes                   | Array of objects| List of folders used as volumes by the stack (can be any folder)                              |
| stacks.volumes.path              | Array of paths| List of folders used as volumes by the container (can be any folder)                          |
| stacks.volumes.maxBackups        | Number       | Number of backups to keep (older backups will be deleted when this limit is reached)          |
| stacks.volumes.preBackupSleep    | Number (sec) | *(Optional)* Seconds to wait before backing up this volume (useful for DB/app flushes)        |

## How to recover a backup!

### 0. See what is inside a backup.tar.gz
Verify what are you going to recover!
```shell
tar -tvf syncthing_syncthing_20241105_162629.tar.gz
```

### 1. Stop de Stack
```shell
docker compose -f /path/to/compose.yml down
```

### 2. Extract the backup
```shell
tar -xzvf /path/to/backup/oring/stack1/volume1/volume1_250902-1900.tar.gz -C /destination/path
```

### 3. Start the Stack
```shell
docker compose -f /path/to/compose.yml up -d
```

# Screenshots
Example of folder structure created by this script:  
![folder structure](https://github.com/MrCaringi/assets/blob/main/images/scripts/container-backups/terminal-folder-structure.jpg)

Example of logs:  
![Logs](https://github.com/MrCaringi/assets/blob/main/images/scripts/container-backups/logs-01.png)

# Changelog
- 2025-09-02  v2.1.0  Now backs up the entire compose folder, logs backup sizes, rotates compose folder backups using the first volume's maxBackups, and supports per-volume delay before backup (`preBackupSleep`). Improved Telegram notifications and warnings about downtime.
- 2025-08-22  v2.0.0  Now compresses backups as `.tar.gz` archives, backup logic by stack/compose, improved error handling
- 2025-05-31  v1.1    Added Telegram thread support, compose file backup, improved error reporting
- 2024-11-18  v1.0    First version
