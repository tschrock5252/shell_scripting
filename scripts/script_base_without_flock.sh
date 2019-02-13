#!/bin/bash

# Set up local script variables
    function DEFINE_VARIABLES {
        TODAYS_DATE=$(date +"%m-%d-%Y");
    }

# Set up a lock to prevent this script from running on top of itself if executed via cron
    function SETUP_LOCK {
        SCRIPT_FILE_NAME=`echo $(basename $0) | sed 's/\..*$//'`;
        LOCK_FILE=/var/lock/$SCRIPT_FILE_NAME.lock;
        touch $LOCK_FILE;
        read lastPID < $LOCK_FILE;
        [ ! -z "$lastPID" -a -d /proc/$lastPID ] && echo "" && echo "# There is another copy of this script currently running. Exiting now for safety purposes." && exit 1
        echo $BASHPID > $LOCK_FILE;
    }

# Define the script exit function to clean up
    function FINISH {
        [ -e /tmp/$$.log ] && rm /tmp/$$.log; # This isn't currently used. But it's a placeholder for a log file
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

