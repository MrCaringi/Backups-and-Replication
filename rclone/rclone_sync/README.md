##   The Idea
I needed a way to syncronize several public clouds folders (team drive for example) for backup purposes.
# RCLONE REPLICATION Script
This is a (very simple) Bash script for syncing directories with rclone remotes or remote-to-remote.
Internally it is (basically) a `rclone sync /origin/ /destination/` automation tool
##  Main (versioned) Features
- Can send Telegram Notifications (messages and log files)
- Validates parallel intances (in order to prevent conflicts)
- origin/remote folder can be easily modificable (for example when a Team Drive is lost, you can remove/add new ones)
- v0.4.0    Feature: Time Elapsed included in logs and notification
- v1.0.0    Feature: All-in-one code refactor
- v1.1.0    Feature: `bwlimit` parameter is available in config file (refer to https://rclone.org/flags/)
- v1.2.0    Feature: Global Flags can be used in a syncronization task
- v1.4.0    Feature: Smart Dedupe based on `rclone sync` logs
- v1.6.0    Feature: Improved Telegram messages format

# How to Use
##  In the Terminal
```
bash rclone_sync.sh config.json
```
Where:
- "rclone_sync.sh" is the script
- "config.json" is the configuration file

# How to update the script
## In the terminal:
`wget -O rclone_sync.sh https://raw.githubusercontent.com/MrCaringi/Backups-and-Replication/master/rclone/rclone_sync/rclone_sync.sh && chmod +x borg.sh`

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
    "selfHealingFeatures":{
        "DedupeFlags": "--dedupe-mode newest",
        "SourceDedupeText": [
            "Duplicate object found in source",
            "Duplicate directory found in source"
        ],
        "DestinationeDedupeText": [
            "Duplicate directory found in destination",
            "Duplicate object found in source"
        ]
        },
    "folders": [
        {
            "From": "/local/path",
            "To": "remote1:",
            "EnableCustomFlags": true,
            "Flags": "--fast-list --drive-export-formats docx,xlsx,pptx,svg --max-transfer=670G --bwlimit=1G",
            "EnableSelfHealing": true
        },
        {
            "From": "remote1:",
            "To": "remote2:",
            "EnableCustomFlags": false,
            "EnableSelfHealing": true
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
| selfHealingFeatures.DedupeFlags | Text | Parameters for `rclone dedupe` command |
| selfHealingFeatures.SourceDedupeText |Text | List of strings used to detect if there duplicated files/folders in Source |
| selfHealingFeatures.DestinationeDedupeText | Text | List of strings used to detect if there duplicated files/folders in Destination |
| folders.From | path/remote | Origin |
| folders.To | path/remote | Destination |
| folders.EnableCustomFlags | true/false | if this parameter is equal to "**true**", then `folders.Flags`will be used as flags for `rclonce sync` command |
| folders.Flags | text | if "**folders.EnableCustomFlags**" is enable for the task, this text will be used instead of `Config.DriveServerSide`, `Config.MaxTransfer` and `Config.BwLimit` parameters |
| folders.EnableSelfHealing | true/false | Enable `rclone dedupe` command for remotes |

### Changelog
- 2021-07-07  First version
- 2021-07-09  Fixing documentation
- 2021-07-18  v0.2    Improved telegram messages
- 2021-07-21  v0.3    Improving concurrence instances validation
- 2021-08-04  v0.4.1  Elapsed time in notification
- 2021-08-06  v0.4.2.3    including DAYS in Elapsed time in notification
- 2021-08-09  v0.5.1    Enable server-side-config and max-tranfer quota
- 2021-08-10  v1.0.1.1  All-in-one
- 2021-08-11  v1.1      Feature: Bandwidth limit
- 2021-08-23  v1.2      Feature: Task's flags
- 2021-08-31  v1.3.1    Feature: Fewer Messages
- 2021-11-11  v1.4.0    Feature: Smart Dedupe
- 2022-01-06  v1.5.0    Fix: Single Task
- 2022-02-15  v1.5.1    Fix: Dedupe Syntax
- 2022-11-21  v1.6.0    Feature: new telegram message format