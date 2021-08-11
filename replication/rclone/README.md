##   The Idea
I needed a way to syncronize several public clouds folders (team drive for example) for backup purposes.
# RCLONE REPLICATION Script
This is a (very simple) Bash script for syncing directories with rclone remotes or remote-to-remote.
Internally it is a `rclone sync /origin/ /destination/` automation tool
##  Features
- Can send Telegram Notifications (message and log files)
- Validates parallel intances
- origin/remote folder can be easily modificable (for example when a Team Drive is lost)
- v0.4  Feature: Time Elapsed included in logs and notification
- v1.0  Feature: All-in-one code refactor
- v1.1  Feature: `bwlimit` parameter is available in config file (refer to https://rclone.org/flags/)
# How to Use
##  In the Terminal
```
bash rclone_sync2.sh rclone_sync2.json
```
Where:
- "rclone_sync2.sh" is the script
- "rclone_sync2.json" is the configuration file

##  How to fill the config file (rclone_sync2.json)
Delete text afte commas (,) in order to use it:
```
{
    "config":{
        "Debug": true,  ->	true/false      This enable/disable more "verbosity" output
        "Wait": 5,      -> 	seconds         Delay between tasks
        "InstanceFile": "/path/rclone_wip.temp",     -> 	file path   In order to prevent concurrence, there is a .temp file validation
        "DriveServerSide": true,       ->   true/false  Enable rclone flag  "--drive-server-side-across-configs" Allow server-side operations to work across different drive configs.
        "MaxTransfer": "670G",          ->  Enable rclone flag "--max-transfer". Maximum size of data to transfer. (default off)
        "BwLimit": "1G"     ->   Bandwidth limit in KiByte/s, or use suffix B|K|M|G|T|P or a full timetable.
        },
    "telegram":{
        "Enable": true,             ->  true/false      Enable Telegram Notifications (you can get this when you add the bot @getmyid_bot to your chat/group)
        "ChatID": "-123456789",     ->  Integer     Number that identify Telegram Chat/Group
        "APIkey": "123:ABCDE"       ->  Text        Telegram Bot API Key
        },


        },
    "folders": [        -> Folder array, you can add as many origin/destination combination you prefer
        {
            "From": "/local/path",
            "To": "remote1:"
        },
        {
            "From": "remote1:",
            "To": "/other_local/path/"
        },
        {
            "From": "remote1:",
            "To": "remote2:"
        },
        {
            "From": "remote2:",
            "To": "remote3:"
        }      
    ]
}

```