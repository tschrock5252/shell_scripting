#!/bin/bash
set -euo pipefail

# Set up global variables
script_file_name=$(basename "$0" | sed 's/\..*$//')
lock_dir="${LOCK_DIR:-/tmp}"
lock_file="${lock_dir}/${script_file_name}.lock"
log_file="/tmp/${script_file_name}_$$.log"

# Function to acquire lock using PID file
acquire_lock() {
    if [ -e "$lock_file" ]; then
        local existing_pid
        existing_pid=$(cat "$lock_file")
        if [ -n "$existing_pid" ] && kill -0 "$existing_pid" 2>/dev/null; then
            echo "ERROR: Another instance of this script (PID $existing_pid) is running. Exiting." >&2
            exit 1
        else
            echo "Stale lock file found. Removing." >&2
            rm -f "$lock_file"
        fi
    fi

    echo "$$" > "$lock_file"
}

# Function to release the lock and cleanup
release_lock() {
    [ -e "$log_file" ] && rm -f "$log_file"
    [ -e "$lock_file" ] && rm -f "$lock_file"
}
trap release_lock EXIT

# Main script logic placeholder
main_script_function() {
    :
}

# Run the script
acquire_lock
main_script_function

