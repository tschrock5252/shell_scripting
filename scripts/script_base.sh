#!/bin/bash

# Set up local script variables
    function DEFINE_VARIABLES {
        flock=$(which flock);
        TODAYS_DATE=$(date +"%m-%d-%Y");
    }

# Set up a lock to prevent this script from running on top of itself if executed via cron
    function SETUP_LOCK {
    # Check if flock is installed. If it's not, exit this script with an error message
        if [ -z "$flock" ]; then
            echo "flock is not currently installed but is required for this script to function. Exiting now.";
            exit 1;
        fi
        set -e; # exit status' > 0 cause the shell to exit immediately
        SCRIPT_FILE_NAME=`echo $(basename $0) | sed 's/\..*$//'`;
        LOCK_FILE="/var/lock/${SCRIPT_FILE_NAME}.lock";
        exec {lock_fd}>$LOCK_FILE || exit 1;
        $flock -n "$lock_fd" || { echo "ERROR: There is already another copy if this script running or setting up a lock using flock failed." >&2; exit 1; }
    }

# Define the script exit function to clean up
    function FINISH {
        [ -e /tmp/$$.log ] && rm /tmp/$$.log; # This isn't currently used. But it's a placeholder for a log file
        flock -u "$lock_fd";
    }
    trap FINISH EXIT

# Define the main script function
    function MAIN_SCRIPT_FUNCTION {
        :
    }
    
# Call all of the script functions
    DEFINE_VARIABLES
    SETUP_LOCK
    MAIN_SCRIPT_FUNCTION

