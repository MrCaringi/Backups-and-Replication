## The Idea behind this Script
I needed a way to backup my Docker volumes in a safe way (by pausing the container) and with minimal downtime.

# CONTAINER BACKUP Script
This is a simple Bash script for generating backups of Docker container volumes.

## Main Features
- Sends Telegram notifications (messages and log files), including support for threads (`MessageThreadID`)
- **Pauses** containers before backup to ensure data consistency
- Uses `tar` to generate and compress backups
- Supports multiple containers and multiple folders (bind volumes) per container
- `maxBackups` can be configured per container
- Supports backing up a `composeFile` per container (optional)
- All logs are saved and sent via Telegram at the end of the process
- Error handling: errors are counted and reported in the final Telegram notification

# How to Use

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

## How to populate the config file (`config.json`)
Example:
```json
{
    "config": {
        "BackupDestination": "/path/to/backup/destination"
    },
    "telegram": {
        "ChatID": "your-chat-id",
        "APIkey": "your-api-key",
        "MessageThreadID": "123" // Optional: Telegram thread ID for group topics
    },
    "containers": [
        {
            "name": "container1",
            "composeFile": "/path/to/compose.yml", // Optional: path to docker-compose file to backup
            "maxBackups": 5,
            "volumes": [
                "/path/to/volume1",
                "/path/to/volume2"
            ]
        },
        {
            "name": "container2",
            "maxBackups": 3,
            "volumes": [
                "/path/to/volume1"
            ]
        }
    ]
}
```

| Parameter                       | Value         | Description                                                                                   |
|----------------------------------|--------------|-----------------------------------------------------------------------------------------------|
| config.BackupDestination         | file path    | Destination for the `*.tar.gz` files. The script creates a subfolder for every container.      |
| telegram.ChatID                  | Number       | Telegram Chat/Group ID (get it by adding `@getmyid_bot` to your chat/group)                   |
| telegram.APIkey                  | Text         | Telegram Bot API Key                                                                          |
| telegram.MessageThreadID         | Number       | *(Optional)* Telegram thread ID for sending messages to a specific topic in groups            |
| containers.name                  | Text         | Name of your container (should match `container_name` in your `docker-compose.yml`)           |
| containers.composeFile           | File path    | *(Optional)* Path to the docker-compose file to backup                                        |
| containers.maxBackups            | Number       | Number of backups to keep (older backups will be deleted when this limit is reached)          |
| containers.volumes               | Array of paths| List of folders used as volumes by the container (can be any folder)                          |

# Screenshots
Example of folder structure created by this script:  
![folder structure](https://github.com/MrCaringi/assets/blob/main/images/scripts/container-backups/terminal-folder-structure.jpg)

Example of logs:  
![Logs](https://github.com/MrCaringi/assets/blob/main/images/scripts/container-backups/logs-01.png)

# Changelog
- 2025-05-31  v1.1  Added Telegram thread support, compose file backup, improved error reporting
- 2024-11-18  v1.0  First version
