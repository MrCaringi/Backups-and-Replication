##   The Idea
I needed a way to check if a remote conection is unavailable, ie when a Team drive got deleted/banned
# RCLONE REMOTE CHECK Script
This is a (very simple) Bash script created in order to check if a RCLONE REMOTE is working.
Internally it is a `rclone lsd <remote>` automation tool

### Telegram Messages
![image](https://user-images.githubusercontent.com/47096567/138532667-0495523e-6ca6-40ab-b49c-dcc2987104c2.png)

### Error Example
![image](https://user-images.githubusercontent.com/47096567/138532708-0d58e469-44d7-4de4-bf9a-0b48425eeea2.png)

### Log
![image](https://user-images.githubusercontent.com/47096567/138532723-7441026e-c21e-4a23-8cef-e5f446cf9f09.png)


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
