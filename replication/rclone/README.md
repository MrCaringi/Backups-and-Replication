##   The Idea
I needed a way to syncronize several public clouds folders (team drive for example) for backup purposes.
# RCLONE REPLICATION Script
This is a (very simple) Bash script for syncing directories with rclone remotes or remote-to-remote.
Internally this is a `rclone sync /origin/ /destination/` automation tool
##  Features
- Can send Telegram Notifications (test and log files)
- Validates parallel intances
- origin/remote folder can be easily modificable (for example when a Team Drive is lost)
- v0.4  Time Elapsed included in logs and notification

# How to Use
##  In the Terminal
```
bash rclone_sync2.sh rclone_sync2.json
```
Where:
- "rclone_sync2.sh" is the script
- "rclone_sync2.json" is the configuration file

##  How to fill the config file (rclone_sync2.json)

```
{
    "config":{        	->	Config Array:
        "Debug": true,  ->	true/false      This enable/disable more "verbosity" output
        "Wait": 5,      -> 	seconds         Delay between tasks
        "InstanceFile": /path/rclone_wip.temp, -> 	file path   In order to prevent concurrence, there is a .temp file validation
        "DriveServerSide": true,        ->  Enable rclone flag  "--drive-server-side-across-configs" Allow server-side operations to work across different drive configs.
        "MaxTransfer": "670G",          ->  Enable rclone flag "--max-transfer". Maximum size of data to transfer. (default off)
        "EnableMessage": true,  ->  true/false      Enable if you have the scripts for Telegram Messages, for more information: https://github.com/MrCaringi/notifications
        "SendMessage": "/home/jfc/scripts/telegram-message.sh",     -> path of the script used to send Telegram Mesage (text only)
        "SendFile": "/home/jfc/scripts/telegram-message-file.sh"    -> path of the script used to send Telegram Mesage with file (logs)

        },
    "folders": [        -> Folder array, you can add as many origin/destination combination you prefer
        {
            "From": "/local/path",
            "To": "remote1:"
        },
        {
            "From": "remote1:",
            "To": "remote2:"
        },
        {
            "From": "remote2:",
            "To": "remote3:"
        },
        {
            "From": "remote3:",
            "To": "remote4:"
        }      
    ]
}

```