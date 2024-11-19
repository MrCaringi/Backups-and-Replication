##   The Idea behind this Script
I needed a way to backup my docker volumes in a safe way ("stopping" the container) and with a minimal downtime.
# CONTAINER BACKUP Script
This is a (very simple) Bash script for generating backups of containers volumes.
##  Main (versioned) Features
- Can send Telegram Notifications (messages and log files)
- This scripts **PAUSES** the containers before the backups
- This script uses `tar` binaries to generate and compress the backups
- Several containers and folders are supported
- `maxBackups` variable can be configured for every container


# How to Use
## How to update/download the script
```shell
wget -O container-backups.sh https://raw.githubusercontent.com/MrCaringi/Backups-and-Replication/master/container-backups/container-backups.sh && chmod +x container-backups.sh
```

##  In the Terminal
```shell
bash container-backups.sh conf_test.json
```
Where:
- `container-backups.sh` is the script
- `conf_test.json` is the configuration file

![Terminal Output](https://github.com/MrCaringi/assets/blob/main/images/scripts/container-backups/terminal.png)

## Cron Job example
You can use `crontab` to schedule this script, an example:
Recomendation: use contrab's `root` in order to prevent preission issues:
```shell
sudo crontab -e
```
Then add this line (adju
```shell
#       container-backups
5 0 * * 1  /folder/location-of-script/container-backups/container-backups.sh /folder/location-of-script/container-backups/conf_weekly.json > /folder/location-of-script/container-backups/conf_weekly.log 2>&1
```

##  How to populate the config file (config.json)
```JSON
{
{
    "config": {
        "BackupDestination": "/path/to/backup/destination"
    },
    "telegram": {
        "ChatID": "your-chat-id",
        "APIkey": "your-api-key"
    },
    "containers": [
        {
            "name": "container1",
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
| Parameter | Value | Description |
|---------------------- | -----------| ---------------------------------|
| Config.BackupDestination | file path | Destination of the `*.tar.gz` files, **this script will create a subfolder for every container!** |
| telegram.ChatID | Number | Number that identify Telegram Chat/Group (you can get this when you add the bot `@getmyid_bot` to your chat/group) |
| telegram.APIkey | Text | Telegram Bot API Key |
| containers.name | text | name of your container, it should be the same you specified as `container_name` in your `docker-compose.yml`  |
| containers.maxBackups | number | Here you can specified how many backups do you want to keep (whe this value is reached, then the older backup will be deleted) |
| containers.volumes | array path | Here you can input the folders path used as volumes by the container (actually you can input any folder) |

# Screenshots
Example of folder structure created by this script:
![folder structure](https://github.com/MrCaringi/assets/blob/main/images/scripts/container-backups/terminal-folder-structure.jpg)

Example of logs:
![Logs](https://github.com/MrCaringi/assets/blob/main/images/scripts/container-backups/logs-01.png)

![Logs](https://github.com/MrCaringi/assets/blob/main/images/scripts/container-backups/logs-02.png)

# Changelog
- 2024-11-18  v1.0   First version
