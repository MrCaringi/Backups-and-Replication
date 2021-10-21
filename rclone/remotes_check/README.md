##   The Idea
I needed a way to check if a remote conection is unavailable, ie when a Team drive got deleted/banned
# RCLONE REMOTE CHECK Script
This is a (very simple) Bash script created in order to check if a RCLONE REMOTE is working.
Internally it is a `rclone lsd <remote>` automation tool
##  Features
- Can send Telegram Notifications (message and log files)
- Remote list is get from `rclone listremotes` results 
# How to Use
##  In the Terminal
```
bash rclone_remote-check.sh config.json
```
Where:
- "rclone_remote-check.sh" is the script
- "config.json" is the configuration file

##  How to fill the config file (rclone_sync2.json)
Delete text afte commas (,) in order to use it:
```
{
    "config":{
        "Debug": true,
        },
    "telegram":{
        "Enable": true,
        "ChatID": "-123456789",
        "APIkey": "123:ABCDE"
        }
}
```
| Parameter | Value | Description |
|---------------------- | -----------| ---------------------------------|
| Config.Debug | true/false | Enable more verbosity in the program log |
| telegram.Enable | true/false | Enable Telegram Notifications |
| telegram.ChatID | Number | Number that identify Telegram Chat/Group (you can get this when you add the bot `@getmyid_bot` to your chat/group) |
| telegram.APIkey | Text | Telegram Bot API Key |

### Changelog
- 2021-10-21	v1.0.0  First version
- 2021-10-21	v1.0.1  Ending Notification message
