# Shell Scripting

These are shell scripts which are meant to be publicly available. They are examples of code which can be used by others to accomplish various tasks. 

## Getting Started

Feel free to follow the instructions below to get a copy of these scripts set up and running on your local machine for development and testing purposes.

### Prerequisites

Since these scripts are all written in bash, they should run natively on most Linux systems without needing much reconfiguration. Each script may require variable changes or some pre-requisite software in order for proper execution, though. Each individual script itself will detail that information.

### Installing

```
Step 1) Fork a copy of the repository on GitHub:
        https://github.com/tschrock5252/shell_scripting

        (Click the "Fork" button on the top right of the repo page.)

Step 2) Clone *your fork* to your local machine:
        git clone git@github.com:your_username/shell_scripting.git

        (This creates the folder and initializes Git with the proper remote.)

Step 3) Add the original repository as an upstream remote:
        cd shell_scripting
        git remote add upstream git@github.com:tschrock5252/shell_scripting.git

        (This lets you pull in future changes from the original repo.)

Step 4) Verify your remotes:
        git remote -v

        You should see something like:
        origin    git@github.com:your_username/shell_scripting.git (fetch)
        upstream  git@github.com:tschrock5252/shell_scripting.git (fetch)

Step 5) Create a new branch to do your work:
        git checkout -b my-feature-branch

        (This helps keep your `master` or `main` clean.)

Step 6) Do your work, commit changes, and push to your fork:
        git add .
        git commit -m "Added feature or fix"
        git push origin my-feature-branch

Step 7) Create a Pull Request from your fork's branch to the original repo:
        Go to your fork on GitHub and click "Compare & pull request"
```

### Scripts

#### daily_backup_vms.sh

This script backs up entire servers via rsync. The way it's currently written, it backs up the entire file system and then excludes specific directories using the "--exclude" option.

This script has four functions in total: 

 - DEFINE_VARIABLES - This function is used to define variables throughout the entire script including the BACKUP_LOG and BACKUP_ERR_LOG variables.
 - SETUP_LOCK - This function defines a lock in /var/lock/script_name.lock which stops this script from running on top of itself. This is useful when executing this via cron.
 - BACKUP_THIS_SERVER - This function is what backs the server up via rsync. Here, variables need defined to make the rsync functional. 
 - FINISH - This function cleans up log files upon script exit and releases the lock which was created in the SETUP_LOCK function.

#### script_base.sh

This is a base which provides a good foundation for shell scripting. There are four functions defined in total:

 - define_variables - This function can be used to define variables throughout the entire script.
 - setup_lock - This function defines a lock using flock in /var/lock/script_name.lock which stops this script from running on top of itself. This is useful when executing via cron.
 - main_script_function - This is a function where all of the primary script logic can be defined.
 - finish - This function cleans up log files upon script exit and releases the lock which was created in the setup_lock function. 

#### script_base_without_flock.sh

This is a base which provides a good foundation for shell scripting. This script also works without flock. There are four functions defined in total:

 - setup_lock - This function defines a lock in /tmp/script_name.lock which stops this script from running on top of itself. This is useful when executing via cron.
 - main_script_function - This is a function where all of the primary script logic can be defined.
 - release_lock - This function cleans up log files upon script exit and releases the lock which was created in the setup_lock function. 

#### syspilot.sh

syspilot was written as a system utility to help troubleshoot systems for Level 1 technicians at my job.
It has the following built-in capabilities: 
 - lsof - List open files.
 - strace - Run an strace on a PID.
 - Memory Utilization - Show current memory allocation.
 - Disk Utilization - Show current disk utilization.
 - Netstat Connections - Display established/closed netstat connections.
 - System Logs - Display various system logs.
 - Tomcat Logs - Display or analyze Tomcat logs.
 - Postgres Logs - Display or analyze Postgres logs.
 - Processes with Threads - Show processes with threads.
 - List Open Ports - List open ports using netstat.
 - Load Stats - Shows the uptime and load stats.
 - tcpdump - Perform an interactive tcpdump (Not for decommissions).
 - Tomcat Thread Dump - Perform a Tomcat Thread dump.
 - Tomcat Heap Dump - Perform a Tomcat Heap dump.
