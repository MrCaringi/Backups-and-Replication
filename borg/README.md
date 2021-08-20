# Borg Backup Script
Bash Script for Borg Backup, Prune and Check

##   BEWARE!
Before use, and in order to make your life easier, learn how to manually use at least these three commands:
- `borg create`
- `borg prune`
- `borg check`

## How to Use
```
#   Open your terminal, then run
bash /path/borg.sh /path/borg.json
```

## Parameters
1 .json file

##  How to fill the config file (.json)
Example
```
{
    "GeneralConfig":{
        "Debug": true,
        "Wait": 2
        },
    "Telegram":{
        "Enable": true,
        "ChatID": "-123",
        "APIkey": "123:ABC"
        },
    "Task": [
        {
            "Repository": "/data/borg-testing/test_repo",
            "BorgPassphrase": "testingtesting", 
            "Prefix": "MyBackup",     
            "BorgCreate":{
                "Enable": true,
                "ArchivePath": "/home/user/",
                "Options": "--stats --info --list --filter=E --compression auto,lzma,9"
                },
            "BorgPrune":{
                "Enable": true,
                "Options": "-v --stats --info --list --keep-daily=7 --keep-weekly=2 --keep-monthly=6"
                },
            "BorgCheck":{
                "Enable": true,
                "Options": "-v --verify-data --show-rc"
                }
        },
        {
            "Repository": "/data/borg-testing/test_repo_2",
            "BorgPassphrase": "testingtesting", 
            "Prefix": "MyOtherBackup",     
            "BorgCreate":{
                "Enable": true,
                "ArchivePath": "/data/Photo/",
                "Options": "--stats --info --list --filter=E --compression auto,lzma,9"
                },
            "BorgPrune":{
                "Enable": true,
                "Options": "-v --stats --info --list --keep-daily=7 --keep-weekly=2 --keep-monthly=6"
                },
            "BorgCheck":{
                "Enable": true,
                "Options": "-v --verify-data --show-rc"
                }
        }    
    ]
}
```
### Instrunctions

