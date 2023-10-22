# Borg Backup Script
Bash Script for Borg Backup, Prune, Compact and Check

##   BEWARE!
**Before use, and in order to make your life easier, learn how to manually use at least these four Borg Commands:**
- `borg create`     https://borgbackup.readthedocs.io/en/stable/usage/create.html
- `borg prune`      https://borgbackup.readthedocs.io/en/stable/usage/prune.html
- `borg compact`    https://borgbackup.readthedocs.io/en/stable/usage/compact.html
- `borg check`      https://borgbackup.readthedocs.io/en/stable/usage/check.html

## How to update the script
```
cd /path/to/the/script/location
wget -O borg.sh https://raw.githubusercontent.com/MrCaringi/Backups-and-Replication/master/borg/borg.sh && chmod +x borg.sh
```

## How to Use
Open your terminal, then run
```
bash /path/borg.sh /path/config.json
```
![Terminal Output](https://github.com/MrCaringi/assets/blob/main/images/scripts/borg/terminal_01.png)

### Parameters
1 .json file

### Packages requirement
- `borg`  Main program
- `jq`    Package for json data parsing

##  How to fill the config file (.json)
Example
```
{
    "GeneralConfig":{
        "Debug": true,
        "Wait": 2,
        "Exports": [
            { "BORG_TEST1": "VALUE_1" },
            { "BORG_TEST2": "VALUE_2" },
            { "BORG_CHECK_I_KNOW_WHAT_I_AM_DOING": "YES" }
            ]
        },
    "Telegram":{
        "Enable": true,
        "ChatID": "-123",
        "APIkey": "123:ABC"
        },
    "Task": [
        {
            "Repository": "/data/borg-testing/test_repo",
            "BorgPassphrase": "testingtrepo_passwordesting", 
            "Prefix": "MyBackup",     
            "BorgCreate":{
                "Enable": true,
                "ArchivePath": "/home/user /another/path /and/another/path",
                "Options": "-v --stats --info --list --filter=E --files-cache ctime,size --compression auto,lzma,6"
                },
            "BorgPrune":{
                "Enable": true,
                "Options": "-v --stats --info --list --keep-daily=7 --keep-weekly=2 --keep-monthly=6"
                },
            "BorgCheck":{
                "Enable": true,
                "Options": "-v --verify-data --show-rc"
                },
            "BorgCompact":{
                "Enable": true,
                "Options": "-v --cleanup-commits --threshold 10"
                }
        },
        {
            "Repository": "/other/borg-repo",
            "BorgPassphrase": "repo_password", 
            "Prefix": "My_Other_Backup",     
            "BorgCreate":{
                "Enable": true,
                "ArchivePath": "/data/pictures",
                "Options": "--stats --info --list --filter=E --files-cache ctime,size --compression auto,lzma,9"
                },
            "BorgPrune":{
                "Enable": true,
                "Options": "-v --stats --info --list --keep-last=5"
                },
            "BorgCheck":{
                "Enable": true,
                "Options": "-v --repository-only --show-rc"
                },
            "BorgCompact":{
                "Enable": true,
                "Options": "-v --cleanup-commits --threshold 10"
                }
        }
    ]
}
```
### .json Instructions
| Parameter | Value | Description |
|---------------------- | -----------| ---------------------------------|
| GeneralConfig.Debug | true / false | Enable more verbosity in the program log |
| GeneralConfig.Wait | number | Seconds to wait between task |
| GeneralConfig.Exports | text | Enable the EXPORT variables which values DOES NOT CONTAINS SPACES OR SPECIAL CHARs, for instance `BORG_CHECK_I_KNOW_WHAT_I_AM_DOING=YES`; if you need to includes variables with specials chars (for example `BORG_RSH="ssh -i /path/to/private/key "), then modify the script at line 38 in order to include those variables. Visit https://borgbackup.readthedocs.io/en/stable/usage/general.html#environment-variables for further info about environment variables|
| Telegram.Enable | true / false | Enable Telegram Notifications |
| Telegram.ChatID | number | Enable Telegram Notifications (you can get this when you add the bot @getmyid_bot to your chat/group) |
| Telegram.APIkey | alphanumeric | Telegram Bot API Key |
| Task.Repository | Path | Full path to Repository |
| Task.BorgPassphrase | alphanumeric | Repository's password |
| Task.Prefix | alphanumeric | Backup Name |
| Task.BorgCreate.Enable | true / false | Enable Backup Creation for this task |
| Task.BorgCreate.ArchivePath | Path | Full path to the folder that is going to be backed up, you can use more than one path, just separate it with spaces |
| Task.BorgCreate.Options | Text | `borg create` options https://borgbackup.readthedocs.io/en/stable/usage/create.html |
| Task.BorgPrune.Enable | true / false | Enable Backup Prune (automatic deletion) for this task |
| Task.BorgPrune.Options | Text | `borg prune` Options https://borgbackup.readthedocs.io/en/stable/usage/prune.html |
| Task.BorgCheck.Enable | true / false | Enable Backup Check for this task |
| Task.BorgCheck.Options | Text | `borg check` Options https://borgbackup.readthedocs.io/en/stable/usage/check.html
| Task.BorgCompact.Enable | true / false | Enable Compact for this task |
| Task.BorgCompact.Options | Text | `borg compact` Options https://borgbackup.readthedocs.io/en/stable/usage/compact.html

##  Screeshots
Telegram Messages:
![Telegram Messages](https://github.com/MrCaringi/assets/blob/main/images/scripts/borg/telegram_01.png)

Telegram Log:
![Telegram Log](https://github.com/MrCaringi/assets/blob/main/images/scripts/borg/log_01.png)
##  Version Story
- 2023-10-20  v1.5.3    Feature: Flexible EXPORT of Variables
- 2023-01-03  v1.5.2    Feature: TOTAL size (compact) in telegram notification/log
- 2022-12-23  v1.5.1    Feature: TOTAL size in telegram notification/log
- 2022-12-13  v1.5.0    Feature: PRUNE size in telegram notification
- 2022-11-18  v1.4.0    Feature: new `jq` package valitation / migrating to `--glob-archives` / improving telegram logs
- 2022-03-23  v1.3.0    Feature: new `Compact` command for borg version 1.2+
- 2021-09-15  v1.2.1    Bug: Number of Files reset
- 2021-09-10  v1.2.0    Feature: Number of Files
- 2021-08-24  v1.1.1    Feature: Fewer Telegram Messages
- 2021-08-20  v1.0.3    Feature: All-in-One code refactor
- 2021-08-07  v0.4    Enable "--prefix PREFIX" for Pruning
- 2021-08-06  v0.3    Disable PRUNE Option
- 2020-04-25  Uploaded a GitHub version
- 2020-04-24  First version