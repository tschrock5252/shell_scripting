# Shell Scripting

These are shell scripts which are meant to be publicly available. They are examples of code which can be used by others to accomplish various tasks. 

## Getting Started

Feel free to follow the instructions below to get a copy of these scripts set up and running on your local machine for development and testing purposes.

### Prerequisites

Since these scripts are all written in bash, they should run natively on most Linux systems without needing much reconfiguration. Each script may require variable changes or some pre-requisite software in order for proper execution, though. Each individual script itself will detail that information.

### Installing

```
Step 1) Fork a copy of the repository in github which is located here: https://github.com/tschrock5252/shell_scripting

Step 2) On your local machine, move to a new folder to work within and create a new git repository with: git init

Step 3) Add a new origin using the following command: git remote add origin git@github.com:your_username/shell_scripting.git

Step 4) Download all files using: git pull origin master
```

### Scripts

#### script_base.sh

This is a base which provides a good foundation for shell scripting. There are four functions defined in total:

 - DEFINE_VARIABLES - This function can be used to define variables throughout the entire script.
 - SETUP_LOCK - This function defines a lock using flock in /var/lock/script_name.lock which stops this script from running on top of itself. This is useful when executing via cron.
 - MAIN_SCRIPT_FUNCTION - This is a function where all of the primary script logic can be defined.
 - FINISH - This function cleans up log files upon script exit and releases the lock which was created in the SETUP_LOCK function. 

#### script_base_without_flock.sh

This is a base which provides a good foundation for shell scripting. This script also works without flock. There are four functions defined in total:

 - DEFINE_VARIABLES - This function can be used to define variables throughout the entire script.
 - SETUP_LOCK - This function defines a lock in /var/lock/script_name.lock which stops this script from running on top of itself. This is useful when executing via cron.
 - MAIN_SCRIPT_FUNCTION - This is a function where all of the primary script logic can be defined.
 - FINISH - This function cleans up log files upon script exit and releases the lock which was created in the SETUP_LOCK function. 

#### daily_backup_vms.sh

This script backs up entire servers via rsync. The way it's currently written, it backs up the entire file system and then excludes specific directories using the "--exclude" option.

This script has four functions in total: 

 - DEFINE_VARIABLES - This function is used to define variables throughout the entire script including the BACKUP_LOG and BACKUP_ERR_LOG variables.
 - SETUP_LOCK - This function defines a lock in /var/lock/script_name.lock which stops this script from running on top of itself. This is useful when executing this via cron.
 - BACKUP_THIS_SERVER - This function is what backs the server up via rsync. Here, variables need defined to make the rsync functional. 
 - FINISH - This function cleans up log files upon script exit and releases the lock which was created in the SETUP_LOCK function.
