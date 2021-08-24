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
- v1.2  Feature: Global Flags can be used in a syncronization task
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
        "Debug": true,
        "Wait": 2,
        "InstanceFile": "/path/rclone.temp",
        "DriveServerSide": true,
        "MaxTransfer": "670G",
        "BwLimit": "1G"
        },
    "telegram":{
        "Enable": true,
        "ChatID": "-123456789",
        "APIkey": "123:ABCDE"
        },
    "folders": [
        {
            "From": "/local/path",
            "To": "remote1:",
            "EnableCustomFlags": true,
            "Flags": "--fast-list --drive-export-formats docx,xlsx,pptx --max-transfer=670G --bwlimit=1G"
        },
        {
            "From": "remote1:",
            "To": "remote2:",
            "EnableCustomFlags": false
        },
        {
            "From": "remote2:",
            "To": "remote3:",
            "EnableCustomFlags": false
        },
        {
            "From": "remote3:",
            "To": "remote4:",
            "EnableCustomFlags": false
        }     
    ]
}
```
| Parameter | Value | Description |
|---------------------- | -----------| ---------------------------------|
| Config.Debug | true/false | Enable more verbosity in the program log |
| Config.Wait | number | Seconds to wait between task |
| Config.InstanceFile | file path | In order to prevent concurrence, there is a .temp file validation |
| Config.DriveServerSide | true/false | Enable rclone flag  `--drive-server-side-across-configs` Allow server-side operations to work across different |
| Config.MaxTransfer | Number + Suffix | Enable rclone flag `--max-transfer`. Maximum size of data to transfer. |
| Config.BwLimit | Number + Suffix | Bandwidth limit in KiByte/s, or use suffix B|K|M|G|T|P or a full timetable |
| telegram.Enable | true/false | Enable Telegram Notifications |
| telegram.ChatID | Number | Number that identify Telegram Chat/Group (you can get this when you add the bot `@getmyid_bot` to your chat/group) |
| telegram.APIkey | Text | Telegram Bot API Key |
| folders.From | path/remote | Origin |
| folders.To | path/remote | Destination |
| folders.EnableCustomFlags | true/false | if this parameter is equal to "**true**", then `folders.Flags`will be used as flags for `rclonce sync` command |
| folders.Flags | text | if "**folders.EnableCustomFlags**" is enable for the task, this text will be used instead of `Config.DriveServerSide`, `Config.MaxTransfer` and `Config.BwLimit` parameters |
