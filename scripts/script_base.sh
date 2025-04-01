#!/bin/bash
set -euo pipefail

# Set up local script variables
define_variables() {
    flock=$(command -v flock)
}

# Set up a lock to prevent this script from running concurrently
setup_lock() {
    if [ -z "$flock" ]; then
        echo "flock is not installed but required. Exiting." >&2
        exit 1
    fi

    script_file_name=$(basename "$0" | sed 's/\..*$//')
    lock_dir="${LOCK_DIR:-/var/lock}"
    lock_file="${lock_dir}/${script_file_name}.lock"

    # Fallback to /tmp if lock file can't be created in /var/lock
    if ! touch "$lock_file" &>/dev/null; then
        lock_file="/tmp/${script_file_name}.lock"
    fi

    exec {lock_fd}>"$lock_file" || exit 1
    $flock -n "$lock_fd" || {
        echo "ERROR: Another copy of this script is already running or flock failed." >&2
        exit 1
    }
}

# Cleanup on exit
finish() {
    [ -e "/tmp/$$.log" ] && rm "/tmp/$$.log"
    flock -u "$lock_fd"
}
trap finish EXIT

# Main script logic
main_script_function() {
    :
}

# Run the script
define_variables
setup_lock
main_script_function
