#!/bin/bash

# Set up local script variables
    function DEFINE_VARIABLES {
        flock=`which flock`;
        mkdir -p /var/log/daily_backup; # Create /var/log/daily_backup if it doesn't exist. This usually errors, but -p hides the error.
        TODAYS_DATE=$(date +"%m-%d-%Y");
        BACKUP_LOG="/var/log/daily_backup/daily_backup.log"; touch $BACKUP_LOG; # Create daily_backup.log if it doesn't exist.
        BACKUP_ERR_LOG="/var/log/daily_backup/$TODAYS_DATE.rsync_err.log";
        rsync=`which rsync`;
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

# This function backs this server up in full
    function BACKUP_THIS_SERVER {

    # Check if rsync is installed. If it's not, exit this script with an error message
        if [ -z "$rsync" ]; then
            echo "rsync is not currently installed but is required for this script to function. Exiting now.";
            exit 1;
        fi
    
    # Define function variables non-specific to the rsync
        BACKUP_SERVER_NAME=backup-server     # Define the backup server name
        BACKUP_DIR1=/mnt/Backup1             # Define the BACKUP_DIR1 location on the backup server
        BACKUP_DIR2=/mnt/Backup2             # Define the BACKUP_DIR2 location on the backup server
        RSYNC_USERNAME=backup-user           # Define the username which should be utilized for backups

    # Backup to $BACKUP_DIR1 on $BACKUP_SERVER_NAME
        BACKUP1_START_TIME=$(date '+%s'); # Gather the backup start time in seconds. This will be used for backup duration math.
        $rsync -a --exclude="/proc/*" --exclude="/mnt/*" --exclude="/srv/*" --exclude="/sys/*" --exclude "/var/log/*" / ${RSYNC_USERNAME}@${BACKUP_SERVER_NAME}:${BACKUP_DIR1}/$(hostname -s)/$TODAYS_DATE 2>/tmp/.log.$$
        RSYNC1_RESULT=$? # Gather the rsync result. This will be a 0 if it succeeded
        BACKUP1_END_TIME=$(date '+%s'); # Gather the backup end time in seconds. This will be used for backup duration math.
        let "BACKUP1_DURATION=BACKUP1_END_TIME-BACKUP1_START_TIME"; # Find and then set BACKUP1_DURATION using BACKUP1_START_TIME and BACKUP1_END_TIME variables
        if [ "${RSYNC1_RESULT}" -ne "0" ]; then # If the rsync result was anything other than 0, it was a failure, and the following occurs
            echo "$TODAYS_DATE - Backup1 Status : Error" >> $BACKUP_LOG;
            echo " - Stats From Run: rsync result (0=Success): ${RSYNC1_RESULT}, Backup1 Duration (seconds): ${BACKUP1_DURATION}" >> $BACKUP_LOG;
            mv /tmp/.log.$$ $BACKUP_ERR_LOG;
        else # If the backup succeeds, this occurs
            echo "$TODAYS_DATE - Backup1 Status : Success" >> $BACKUP_LOG;
            echo " - Stats From Run: rsync result (0=Success): ${RSYNC1_RESULT}, Backup1 Duration (seconds): ${BACKUP1_DURATION}" >> $BACKUP_LOG;
            rm -f /tmp/.log.$$;
        fi
    # Backup to $BACKUP_DIR2 on $BACKUP_SERVER_NAME
        BACKUP2_START_TIME=$(date '+%s'); # Gather the backup start time in seconds. This will be used for backup duration math.
        $rsync -a --exclude="/proc/*" --exclude="/mnt/*" --exclude="/srv/*" --exclude="/sys/*" --exclude "/var/log/*" / ${RSYNC_USERNAME}@${BACKUP_SERVER_NAME}:${BACKUP_DIR2}/$(hostname -s)/$TODAYS_DATE 2>/tmp/.log.$$
        RSYNC2_RESULT=$? # Gather the rsync result. This will be a 0 if it succeeded
        BACKUP2_END_TIME=$(date '+%s'); # Gather the backup end time in seconds. This will be used for backup duration math.
        let "BACKUP2_DURATION=BACKUP2_END_TIME-BACKUP2_START_TIME"; # Find and then set BACKUP2_DURATION using BACKUP2_START_TIME and BACKUP2_END_TIME variables
        if [ "${RSYNC2_RESULT}" -ne "0" ]; then # If the rsync result was anything other than 0, it was a failure, and the following occurs
            echo "$TODAYS_DATE - Backup2 Status : Error" >> $BACKUP_LOG;
            echo " - Stats From Run: rsync result (0=Success): ${RSYNC2_RESULT}, Backup2 Duration (seconds): ${BACKUP2_DURATION}" >> $BACKUP_LOG;
            mv /tmp/.log.$$ $BACKUP_ERR_LOG;
        else # If the backup succeeds, this occurs
            echo "$TODAYS_DATE - Backup2 Status : Success" >> $BACKUP_LOG;
            echo " - Stats From Run: rsync result (0=Success): ${RSYNC2_RESULT}, Backup2 Duration (seconds): ${BACKUP2_DURATION}" >> $BACKUP_LOG;
            rm -f /tmp/.log.$$;
        fi
    }

# Define the script exit function to clean up
    function finish {
        [ -e /tmp/.log.$$ ] && rm /tmp/.log.$$; # This removes any logs that are created by the backup
    }
    trap finish EXIT

# Call Script Functions
    DEFINE_VARIABLES
    SETUP_LOCK
    BACKUP_THIS_SERVER
