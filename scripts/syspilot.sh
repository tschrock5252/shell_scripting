#!/bin/bash

# Author     : Tyler Schrock
# Version    : 2024.04.04 (Tyler Schrock)
# Description: This script provides various system utilities and information.

showHelp() {
    echo "Usage: syspilot.sh [option]"
    echo
    echo "Overview"
    echo "  This script provides various system utilities and information."
    echo ""
    echo "Options:"
    echo "  -h              Display this help message."
    echo ""
    echo "  -d              Run a set of commands for quick diagnostics."
    echo "                  This includes lsof, memory utilization, disk usage, netstat for"
    echo "                  established/closed connections, processes with threads, open "
    echo "                  ports, load stats, a 30 second tcpdump, and a tomcat thread dump."
    echo "                  These files are automatically compressed. You will be prompted"
    echo "                  whether you want to keep the non-encrypted files at the end"
    echo "                  of the script execution."
    echo ""
    echo "  -q              Runs the commands from -d. Removes the non-encrypted files."
    echo "                  Performs all the listed work quietly and without prompt."
    echo ""
    echo "  No option       Run in interactive mode with a menu of utilities to choose from."
    echo ""
    echo "Available Utilities in Interactive Mode:"
    echo "  lsof *                    List open files."
    echo "  strace *                  Run an strace on a PID."
    echo "  Memory Utilization *      Show current memory allocation."
    echo "  Disk Utilization          Show current disk utilization."
    echo "  Netstat Connections *     Display established/closed netstat connections."
    echo "  System Logs               Display various system logs."
    echo "  Tomcat Logs               Display or analyze Tomcat logs."
    echo "  Postgres Logs             Display or analyze Postgres logs."
    echo "  Processes with Threads *  Show processes with threads."
    echo "  List Open Ports           List open ports using netstat."
    echo "  Load Stats                Shows the uptime and load stats."
    echo "  tcpdump *                 Perform an interactive tcpdump (Not for decommissions)."
    echo "  Tomcat Thread Dump *      Perform a Tomcat Thread dump."
    echo "  Tomcat Heap Dump *        Perform a Tomcat Heap dump."
    echo
    echo "  Note: Each option with an asterisk * can be output to a file."
}

# Defines global variables.
globalVars() {
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    BOLD='\033[1m'
    NO_COLOR='\033[0m'
}

# Define a helper function that converts megabytes and gigabytes to bytes.
convert_to_bytes() {
    echo $1 | awk '/[0-9]$/ {print $1; next};
                   /[Mm]$/ {print $1*1024*1024; next};
                   /[Gg]$/ {print $1*1024*1024*1024}'
}

# Defines the outputToFile helper function.
outputToFile() {
    local command="$1"
    local description="$2"
    read -p "Output to a file? (yes/no): " outputToFile
    if [ "$outputToFile" = "yes" ] || [ "$outputToFile" = "y" ]; then
        local hostname=$(hostname)
        local filename="${description}_${hostname}_$(date +%Y%m%d%H%M%S).txt"
        eval "$command" > "$filename"
        echo "Output saved to $filename"
    else
        eval "$command"
    fi
}

# Defines the is_number helper function to validate that input is a number
is_number() {
    if ! [[ "$1" =~ ^[0-9]+$ ]]; then
        echo "Error: Input is not a valid number."
        return 1
    fi
    return 0
}

# Function to determine the monitoring URL(s) for this server
showMonitoring() {
    # Determine the lifecycle and OS version.
    os_version=$(cat /etc/*release | grep "DISTRIB_RELEASE" | awk -F "DISTRIB_RELEASE=" '{print $2}');
    server_lifecycle=$(echo $HOSTNAME | awk -F "-" '{print $2}');
    # Determine monitoring URLs based on the lifecycle and OS version.
    if [ "$os_version" = "16.04" ]; then
        if [ "$server_lifecycle" = "d" ] || [ "$server_lifecycle" = "t" ]; then
            monitoring_url="<anonymized_for_github>";
            echo "Server Monitoring URL: ${monitoring_url}" && echo;
        else
            monitoring_url="<anonymized_for_github>";
            echo "Server Monitoring URL: ${monitoring_url}" && echo;
        fi
    elif [ "$os_version" = "18.04" ] || [ "$os_version" = "20.04" ]; then
        monitoring_url="<anonymized_for_github>";
        echo "Server Monitoring URL: ${monitoring_url}" && echo;
    fi
}

# Function to display the troubleshooting menu.
showMenu() {
    while true; do
        showMonitoring;
        echo "Select options:"
        options=("lsof" "Run strace" "Memory Utilization" "Disk Utilization" "Netstat Connections" "System Logs" "Display Tomcat Logs" "Analyze Tomcat Logs" "Display PostgreSQL Logs" "Analyze PostgreSQL Logs" "Processes with Threads" "List Open Ports" "Load Stats" "tcpdump (non-decom)" "Tomcat Thread Dump" "Tomcat Heap Dump (May cause outage)")
        select opt in "${options[@]}" "Quit"; do
            case $REPLY in
                1) checkLsof ;;
                2) runStrace ;;
                3) showMemoryUtilization ;;
                4) showDiskUtilization ;;
                5) showNetstatConnections ;;
                6) displayLog ;;
                7) displayTomcatLog ;;
                8) analyzeTomcatLogs ;;
                9) displayPostgresLogs ;;
                10) analyzePostgresLogs ;;
                11) showProcessesWithThreads ;;
                12) listOpenPorts ;;
                13) showLoadStats ;;
                14) performTcpdump ;;
                15) performTomcatThreadDump ;;
                16) performTomcatHeapDump ;;
                $((${#options[@]}+1))) echo "Exiting..."; exit 0 ;;
                *) echo "Invalid option $REPLY"; continue ;;
            esac
            break
        done
        echo && echo "Press enter to continue..."
        read
    done
}

# Defines the checkLsof function which will list open files.
checkLsof() {
    local autoOutputToFile=$1  # Argument to determine automatic output to file

    if [ "$autoOutputToFile" = "yes" ]; then
        local hostname=$(hostname)
        local filename="lsof_${hostname}_$(date +%Y%m%d%H%M%S).txt"
        sudo lsof -lnP > "$filename"
        echo "$filename" # Return the filename
    else
        read -p "Output to a file? (yes/no): " outputToFile
        if [ "$outputToFile" = "yes" ] || [ "$outputToFile" = "y" ]; then
            echo -e "${BOLD}Executing command${NO_COLOR}: sudo lsof -lnP"
            local hostname=$(hostname)
            local filename="lsof_${hostname}_$(date +%Y%m%d%H%M%S).txt"
            sudo lsof -lnP > "$filename"
            echo "lsof output saved to $filename"
        else
            sudo lsof -lnP
            echo && echo -e "${BOLD}Executed command${NO_COLOR}: sudo lsof -lnP"
        fi
    fi
}

# Defines the runStrace function which will perform an strace.
runStrace() {
    read -p "Enter the number of seconds to run strace (0 for no limit): " duration
    echo
    if ! is_number "$duration"; then
        echo "Invalid duration. Please enter a numeric value."
        return
    fi

    pg_pid=$(ps aux | grep [p]ostgresql | awk '{print $2}')
    tomcat_pid=$(ps aux | grep [t]omcat | awk '{print $2}')

    echo "Common Processes:"

    if [[ -n "$pg_pid" ]]; then
        echo " - PostgreSQL PID: $pg_pid"
    fi

    if [[ -n "$tomcat_pid" ]]; then
        echo " - Tomcat PID: $tomcat_pid"
    fi

    echo
    read -p "Enter the PID of the process to trace: " pid
    local command="strace"
    local hostname=$(hostname)

    if is_number "$pid"; then
        sudo mkdir -p strace_${hostname}_$pid
        command="sudo timeout $duration $command -p $pid -ff -t -q -o strace_${hostname}_$pid/strace_${hostname}.subprocess"
        eval "sudo $command"
        sudo chmod -R 777 strace_${hostname}_$pid/
        echo "strace output saved to the strace_${hostname}_$pid directory."
        echo && echo -e "${BOLD}Executed command${NO_COLOR}: ${command}"
    else
        echo "Invalid PID. Please enter a numeric value."
        return
    fi
}

# Defines the showMemoryUtilization function which will show current memory allocation.
showMemoryUtilization() {
    local autoOutputToFile=$1  # Argument to determine automatic output to file

    if [ "$autoOutputToFile" = "yes" ]; then
        local hostname=$(hostname)
        local filename="memory_utilization_${hostname}_$(date +%Y%m%d%H%M%S).txt"
        free -h > "$filename"
        echo "$filename"  # Return the filename
    else
        read -p "Output to a file? (yes/no): " outputToFile
        if [ "$outputToFile" = "yes" ] || [ "$outputToFile" = "y" ]; then
            echo -e "${BOLD}Executing command${NO_COLOR}: free -h"
            local hostname=$(hostname)
            local filename="memory_utilization_${hostname}_$(date +%Y%m%d%H%M%S).txt"
            free -h > "$filename"
            echo "Memory utilization output saved to $filename"
        else
            echo -e "${BOLD}Executing command${NO_COLOR}: free -h"
            free -h
        fi
    fi
}

# Defines the showDiskUtilization function which will show current disk usage.
showDiskUtilization() {
    local autoOutputToFile=$1  # Argument to determine automatic output to file

    if [ "$autoOutputToFile" = "yes" ]; then
        local hostname=$(hostname)
        local filename="disk_utilization_${hostname}_$(date +%Y%m%d%H%M%S).txt"
        df -h > "$filename"
        echo "$filename"  # Return the filename
    else
        echo -e "${BOLD}Executing command${NO_COLOR}: df -h"
        df -h
    fi
}

# Defines the showNetstatConnections function which will display established netstat connections.
showNetstatConnections() {
    local autoOutputToFile=$1  # Argument to determine automatic output to file

    if [ "$autoOutputToFile" = "yes" ]; then
        local hostname=$(hostname)
        local filename="netstat_${hostname}_$(date +%Y%m%d%H%M%S).txt"
        sudo netstat -a | grep 'EST\|CLOSE' > "$filename"
        echo "$filename"  # Return the filename
    else
        read -p "Output to a file? (yes/no): " outputToFile
        if [ "$outputToFile" = "yes" ] || [ "$outputToFile" = "y" ]; then
            local hostname=$(hostname)
            local filename="netstat_${hostname}_$(date +%Y%m%d%H%M%S).txt"
            echo -e "${BOLD}Executing command${NO_COLOR}: sudo netstat -a | grep 'EST\|CLOSE'"
            sudo netstat -a | grep 'EST\|CLOSE' > "$filename"
            echo "Netstat output saved to $filename"
        else
            echo -e "${BOLD}Executing command${NO_COLOR}: sudo netstat -a | grep 'EST\|CLOSE'"
            sudo netstat -a | grep 'EST\|CLOSE'
        fi
    fi
}

# Defines the displayLog function, which can show system logs.
displayLog() {
    # Determine the operating system type
    local osName=$(awk -F= '/^NAME/{print $2}' /etc/os-release | tr -d '"')

    echo "Select log file to view:"
    local logOptions=()  # Initialize empty array for log options

    # Define log options based on OS type
    if [[ "$osName" == *"Ubuntu"* ]]; then
        logOptions=("syslog" "syslog.1" "auth.log" "dpkg.log" "dmesg")
    elif [[ "$osName" == *"Red Hat"* ]] || [[ "$osName" == *"CentOS"* ]]; then
        # Automatically find and list all messages log files including rotated ones
        mapfile -t messagesLogs < <(sudo find /var/log -name 'messages*' -exec basename {} \;)
        logOptions=("secure" "yum.log" "dmesg" "${messagesLogs[@]}")  # Append all messages logs
    else
        echo "Unsupported OS for this script"
        return
    fi

    select logChoice in "${logOptions[@]}"; do
        if [[ "$logChoice" == "dmesg" ]]; then
            read -p "Enter the number of lines to display: " numLines
            if is_number "$numLines"; then
                dmesg | tail -n $numLines
            fi
        else
            if [[ -f "/var/log/$logChoice" ]]; then
                read -p "Enter the number of lines to display: " numLines
                if is_number "$numLines"; then
                    sudo tail -n $numLines "/var/log/$logChoice"
                fi
            else
                echo "/var/log/$logChoice not found."
            fi
        fi
        break
    done
}

# Defines the displayTomcatLog which can show logs for catalina.out as well as specific applications.
displayTomcatLog() {
    local catalinaLogFile="/var/log/tomcat8/catalina.out"
    local deployLogFile="/var/log/deploy_web_applications.sh.log"

    if [[ ! -f $catalinaLogFile ]]; then
        echo "This is not a Tomcat server, or catalina.out log file does not exist."
        return
    fi

    echo "Select a log to view:"
    echo "1) catalina.out"
    echo "2) deploy_web_applications.sh.log"
    webappLogs=(/var/log/webapps/*)
    for i in "${!webappLogs[@]}"; do
        webappLogs[$i]="${webappLogs[$i]##*/}"
        echo "$((i + 3))) ${webappLogs[$i]}"
    done

    read -p "Enter your choice: " choice

    if [ "$choice" -eq 1 ]; then
        read -p "Enter the number of lines to display from catalina.out: " numLines
        if is_number "$numLines"; then
            sudo tail -n "$numLines" "$catalinaLogFile"
        fi
    elif [ "$choice" -eq 2 ]; then
        if [[ -f $deployLogFile ]]; then
            read -p "Enter the number of lines to display from deploy_web_applications.sh.log: " numLines
            if is_number "$numLines"; then
                sudo tail -n "$numLines" "$deployLogFile"
            fi
        else
            echo "$deployLogFile not found."
        fi
    else
        local appIndex=$((choice - 3))
        if [[ -d "/var/log/webapps/${webappLogs[$appIndex]}" ]]; then
            read -p "Enter the number of lines to display: " numLines
            if is_number "$numLines"; then
                local serverHostname=$(hostname)
                sudo tail -n "$numLines" "/var/log/webapps/${webappLogs[$appIndex]}/${webappLogs[$appIndex]}_${serverHostname}.log"
            fi
        else
            echo "Invalid selection. Please try again."
        fi
    fi
}

# Defines the analyzeTomcatLogs function which can search for WARN and ERROR messages.
analyzeTomcatLogs() {
    local catalinaLogFile="/var/log/tomcat8/catalina.out"
    local deployLogFile="/var/log/deploy_web_applications.sh.log"

    if [[ ! -f $catalinaLogFile ]]; then
        echo "This is not a Tomcat server, or catalina.out log file does not exist."
        return
    fi

    echo "Select a log to analyze:"
    echo "1) catalina.out"
    echo "2) deploy_web_applications.sh.log"
    webappLogs=(/var/log/webapps/*)
    for i in "${!webappLogs[@]}"; do
        webappLogs[$i]="${webappLogs[$i]##*/}"
        echo "$((i + 3))) ${webappLogs[$i]}"
    done

    read -p "Enter your choice: " choice
    local logFile

    if [ "$choice" -eq 1 ]; then
        logFile="$catalinaLogFile"
    elif [ "$choice" -eq 2 ]; then
        logFile="$deployLogFile"
    else
        local appIndex=$((choice - 3))
        logFile="/var/log/webapps/${webappLogs[$appIndex]}/${webappLogs[$appIndex]}_$(hostname).log"
    fi

    if [ -f "$logFile" ]; then
        read -p "Enter the number of context lines to display around WARN and ERROR statements: " contextLines
        if is_number "$contextLines"; then
            echo "Analyzing $logFile for WARN and ERROR statements with $contextLines lines of context..."
            grep -E -C "$contextLines" "WARN|ERROR" "$logFile"
        else
            echo "Invalid input. Please enter a valid number."
        fi
    else
        echo "Log file not found."
    fi
}

# Defines the displayPostgresLogs function which can show logs the latest PG logs.
displayPostgresLogs() {
    # Check if PostgreSQL service is running.
    if ! systemctl is-active --quiet postgresql; then
        echo "PostgreSQL service is not running."
        return
    fi

    # Determine PostgreSQL version
    local pgVersion=$(psql -V | awk '{print $3}' | cut -d '.' -f1)
    echo "Detected PostgreSQL version: $pgVersion"

    # Determine log file directory based on version
    local logDir
    case "$pgVersion" in
        9)
            logDir="/var/lib/postgresql/9.5/main/pg_log"
            ;;
        10)
            logDir="/var/lib/postgresql/10/main/pg_log"
            ;;
        12)
            logDir="/var/lib/postgresql/12/main/pg_log"
            ;;
        *)
            echo "Unsupported PostgreSQL version for this script."
            return
            ;;
    esac

    # Find the most recent log file in the directory.
    local logFile=$(sudo ls -t "$logDir" | head -n 1)
    if [[ -z "$logFile" ]]; then
        echo "No log files found in $logDir"
        return
    fi
    local fullPath="$logDir/$logFile"

    # Display options for the log file.
     if sudo test -f "$fullPath"; then
        read -p "Enter the number of lines to display: " numLines
        if is_number "$numLines"; then
            sudo tail -n "$numLines" "$fullPath"
        else
            echo "Invalid number of lines."
        fi
    else
        echo "Log file not found at expected location: $fullPath"
    fi
}

# Defines the analyzePostgresLogs function which can search PG logs for specific words.
analyzePostgresLogs() {
    # Check if PostgreSQL service is running.
    if ! systemctl is-active --quiet postgresql; then
        echo "PostgreSQL service is not running."
        return
    fi

    # Determine PostgreSQL version.
    local pgVersion=$(psql -V | awk '{print $3}' | cut -d '.' -f1)
    echo "Detected PostgreSQL version: $pgVersion"

    # Determine log file directory based on version
    local logDir
    case "$pgVersion" in
        9)
            logDir="/var/lib/postgresql/9.5/main/pg_log"
            ;;
        10)
            logDir="/var/lib/postgresql/10/main/pg_log"
            ;;
        12)
            logDir="/var/lib/postgresql/12/main/pg_log"
            ;;
        *)
            echo "Unsupported PostgreSQL version for this script."
            return
            ;;
    esac

    # Find the most recent log file in the directory.
    local logFile=$(sudo ls -t "$logDir" | head -n 1)
    if [[ -z "$logFile" ]]; then
        echo "No log files found in $logDir"
        return
    fi
    local fullPath="$logDir/$logFile"

    # Check if the log file exists and analyze for specific words
    if sudo test -f "$fullPath"; then
        echo "Analyzing $fullPath for ERROR, FATAL, and SHUTDOWN messages..."
        sudo grep -E "ERROR|FATAL|SHUTDOWN" "$fullPath"
    else
        echo "Log file not found at expected location: $fullPath"
    fi
}

# Defines the showProcessesWithThreads function, which shows all running processes and associated threads.
showProcessesWithThreads() {
    local autoOutputToFile=$1  # Argument to determine automatic output to file

    if [ "$autoOutputToFile" = "yes" ]; then
        local hostname=$(hostname)
        local filename="processes_with_threads_${hostname}_$(date +%Y%m%d%H%M%S).txt"
        sudo ps -eLf > "$filename"
        echo "$filename"  # Return the filename
    else
        echo -e "${BOLD}Executing command${NO_COLOR}: sudo ps -eLf"
        outputToFile "sudo ps -eLf" "processes_with_threads"
    fi
}

# Defines the listOpenPorts function, which shows open ports.
listOpenPorts() {
    local autoOutputToFile=$1  # Argument to determine automatic output to file

    if [ "$autoOutputToFile" = "yes" ]; then
        local hostname=$(hostname)
        local filename="open_ports_${hostname}_$(date +%Y%m%d%H%M%S).txt"
        sudo netstat -tulnp > "$filename"
        echo "$filename"  # Return the filename
    else
        read -p "Output to a file? (yes/no): " outputToFile
        if [ "$outputToFile" = "yes" ] || [ "$outputToFile" = "y" ]; then
            local hostname=$(hostname)
            local filename="open_ports_${hostname}_$(date +%Y%m%d%H%M%S).txt"
            echo -e "${BOLD}Executing command${NO_COLOR}: sudo netstat -tulnp"
            sudo netstat -tulnp > "$filename"
            echo "open ports output saved to $filename"
        else
            echo -e "${BOLD}Executing command${NO_COLOR}: sudo netstat -tulnp"
            sudo netstat -tulnp
        fi
    fi
}

# Defines the showLoadStats. This shows brief load stats, but is not nearly as information as top/htop.
showLoadStats() {
    local autoOutputToFile=$1  # Argument to determine automatic output to file

    if [ "$autoOutputToFile" = "yes" ]; then
        local hostname=$(hostname)
        local filename="load_stats_${hostname}_$(date +%Y%m%d%H%M%S).txt"
        uptime > "$filename"
        echo "$filename"  # Return the filename
    else
        echo && echo -e "${BOLD}Executing command${NO_COLOR}: uptime    # This contains load stats"
        echo && uptime
    fi
}

# Defines the performTcpdump function. This function takes a quick tcpdump.
performTcpdump() {
    local autoDefaults=$1  # Argument to determine automatic defaults

    local interface duration protocol readable removePcap
    if [ "$autoDefaults" = "yes" ]; then
        # Set default values
        interface=$(ip link show | awk -F: '$0 !~ "lo|virbr|docker|^[^0-9]"{print $2;getline}' | awk '{print $1}' | head -n 1)
        duration=30
        protocol="tcp"
        readable="yes"
        removePcap="yes"
    else
        # Interactive mode to choose parameters
        echo "tcpdump Notice:"
        echo " - This option plans to create two files: one named <interface>_capture.plaintext.log and one file named <interface>_capture.pcap"
        echo " - You will be given the option to delete the pcap during the following prompts."
        echo
        echo "Available Network Interfaces:"
        interfaces=( $(ip link show | awk -F: '$0 !~ "lo|virbr|docker|^[^0-9]"{print $2;getline}') )
        select interface in "${interfaces[@]}"; do
            if [[ " ${interfaces[*]} " =~ " ${interface} " ]]; then
                echo "Selected interface: $interface"
                break
            else
                echo "Invalid selection. Please try again."
            fi
        done
        read -p "Enter duration (in seconds): " duration
        read -p "Enter protocol (tcp/udp): " protocol
        read -p "Make the output more readable? (yes/no): " readable
        read -p "Do you want to remove the .pcap file (yes/no): " removePcap
    fi

    # Execute tcpdump with the specified or default parameters
    pcapFile="${interface}_capture.pcap"

    sudo tcpdump -i "$interface" -w "$pcapFile" -l "$protocol" -G "$duration" -W 1 2> /dev/null

    if [ "$readable" = "yes" ] || [ "$readable" = "y" ]; then
        sudo tcpdump -A -r "$pcapFile" > "${interface}_capture.plaintext.log" 2> /dev/null
        sudo grep "IP" "${interface}_capture.plaintext.log" > "${interface}_capture.plaintext_readable.log"
        sudo rm "${interface}_capture.plaintext.log" && sudo mv "${interface}_capture.plaintext_readable.log" "${interface}_capture.plaintext.log"
    else
        sudo tcpdump -A -r "$pcapFile" > "${interface}_capture.plaintext.log"
    fi

    if [ "$removePcap" = "yes" ] || [ "$removePcap" = "y" ]; then
        sudo rm "$pcapFile"
    else
        sudo chown $(whoami):$(id -gn) "$pcapFile"
    fi

    local filename="${interface}_capture.plaintext.log"
    echo "$filename"  # Return the filename
}

# Defines the performTomcatThreadDump function. This function takes a tomcat8 thread dump.
performTomcatThreadDump() {
    local autoOutputToFile=$1  # Argument to determine automatic defaults
    local tomcatPid=$(ps -ef | grep '[t]omcat8' | awk '{print $2}')

    if [ "$autoOutputToFile" = "yes" ]; then
        if [ -z "$tomcatPid" ]; then
            return
        fi
        # Automatic operation without prompt
        local hostname=$(hostname)
        local filename="tomcat_thread_dump_${hostname}_$(date +%Y%m%d%H%M%S).txt"
        sudo -u tomcat8 jstack -l $tomcatPid > "$filename"
        echo "$filename"  # Return the filename
    else
        if [ -z "$tomcatPid" ]; then
            echo "Tomcat 8 does not appear to be running."
            return
        fi
        # Interactive operation with prompt
        echo "Performing a thread dump is a safe operation and will not cause an outage of Tomcat 8."
        read -p "Proceed (yes/no): " ProceedWithThreadDump
        if [ "$ProceedWithThreadDump" = "yes" ] || [ "$ProceedWithThreadDump" = "y" ]; then
            local hostname=$(hostname)
            local filename="tomcat_thread_dump_${hostname}_$(date +%Y%m%d%H%M%S).txt"
            echo -e "${BOLD}Executing command${NO_COLOR}: sudo -u tomcat8 jstack -l $tomcatPid > "$filename""
            sudo -u tomcat8 jstack -l $tomcatPid > "$filename"
            echo "Thread dump saved to $filename"
        else
            return
        fi
    fi
}

# Defines the performTomcatHeapDump function. This function takes a tomcat8 heap dump.
performTomcatHeapDump() {
    local tomcatPid=$(ps -ef | grep '[t]omcat8' | awk '{print $2}')

    if [ -z "$tomcatPid" ]; then
        echo "Tomcat 8 does not appear to be running."
        return
    fi

    echo && echo -e "${BOLD}${RED}WARNING! THE FOLLOWING OPERATIONS RISK CAUSING A TOMCAT OUTAGE! PROCEED WITH CAUTION!${NO_COLOR}" && echo

    read -p "Is the server out of the load balancer? (yes/no): " outOfBalancer
    if [ "$outOfBalancer" = "yes" ] || [ "$outOfBalancer" = "y" ]; then
        read -p "Are you sure you want to take a heap dump? This could cause an outage if the system hasn't already crashed. Also, please be sure to monitor the file system space while you do this! (yes/no): " confirmHeapDump
        if [ "$confirmHeapDump" = "yes" ] || [ "$confirmHeapDump" = "y" ]; then

            # Read Xmx value from the tomcat configuration.
            XMX_VALUE=$(grep '^JAVA_OPTS' /etc/default/tomcat8 | sed -n 's/.*-Xmx\([0-9]*[MmGg]\).*/\1/p')

            # Convert Xmx value to bytes.
            XMX_BYTES=$(convert_to_bytes $XMX_VALUE)

            # Get free disk space in bytes.
            FREE_DISK_SPACE=$(df --output=avail -B1 "$PWD" | tail -n1)

            # Compare and print message.
            if [ "$FREE_DISK_SPACE" -ge "$XMX_BYTES" ]; then
                :;
            else
                echo -e "${BOLD}${RED}Warning! The disk will likely fill during the heap dump. Please free space before trying again. Exiting now for safety purposes!${NO_COLOR}"
                return
            fi
            local jmapPath="/usr/lib/jvm/java-8-openjdk-amd64/bin/jmap"
            local hostname=$(hostname)
            local filename="tomcat_heap_dump_${hostname}_$(date +%Y%m%d%H%M%S).hprof"
            echo -e "${BOLD}Executing command${NO_COLOR}: sudo -u tomcat8 $jmapPath -dump:file="$filename" $tomcatPid"
            sudo -u tomcat8 $jmapPath -dump:file="$filename" $tomcatPid
            if [ -f $filename ]; then
                echo "Heap dump saved to $filename"
            else
                # Get the permissions of the current directory.
                current_dir_perm=$(stat -c "%a" .)

                # Get the owner of the current directory.
                current_dir_owner=$(stat -c "%U" .)

                # Check if permissions are 777 and the owner is tomcat8.
                if [ "$current_dir_perm" -eq 777 ] && [ "$current_dir_owner" == "tomcat8" ]; then
                    echo "Ownership and permissions for this directory should allow for the tomcat8 user to take heap dumps. Please troubleshoot."
                else
                    echo "The heap dump failed. Please make sure the tomcat8 user has permissions in the current directory."
                fi
            fi
        fi
    elif [ "$outOfBalancer" = "no" ]; then
        echo "Please take the server out of the load balancer before proceeding."
    fi
}

# Main.

# Source prerequisite scripts.
if [ -f /usr/local/share/bash/functions.sh ]; then
    source /usr/local/share/bash/functions.sh
fi

# Call the globalVars function.
globalVars

case "$1" in
    -h)
        # Show help information.
        showHelp
        ;;
    -d)
        lsofFile=$(checkLsof yes)  # Collecting the filename from checkLsof
        OpenPortsFile=$(listOpenPorts yes)  # Collecting the filename from listOpenPorts
        DiskUtilizationFile=$(showDiskUtilization yes)  # Collection the filename from showDiskUtilization
        LoadStatsFile=$(showLoadStats yes)  # Collecting the load stats from showLoadStats
        MemoryUtilizationFile=$(showMemoryUtilization yes)  # Collecting the memory utilization from MemoryUtilizationFile
        NetstatConnectionsFile=$(showNetstatConnections yes)  # Collecting the netstat details from showNetstatConnections
        ProcessesWithThreadsFile=$(showProcessesWithThreads yes)  # Collecting the processes & threads from showProcessesWithThreads
        tcpdumpFile=$(performTcpdump yes)  # Collecting the filename from performTcpdump
        TomcatThreadDumpFile=$(performTomcatThreadDump yes)  # Collecting the filename from performTomcatThreadDump

        # Create an array to hold all filenames
        outputFiles=($lsofFile $OpenPortsFile $DiskUtilizationFile $LoadStatsFile $MemoryUtilizationFile $NetstatConnectionsFile $ProcessesWithThreadsFile $tcpdumpFile $TomcatThreadDumpFile)

        tar -czvf "diagnostics_$(hostname)_$(date +%Y%m%d%H%M%S).tar.gz" "${outputFiles[@]}"
        echo "Files zipped into diagnostics_$(hostname)_$(date +%Y%m%d%H%M%S).tar.gz"

        echo
        read -p "Would you like to KEEP the gathered diagnostic files that have now been compressed? This script plans to delete them. (yes/no): " deleteResponse
        if [ "$deleteResponse" = "yes" ] || [ "$deleteResponse" = "y" ]; then
            :;
        else
            for file in "${outputFiles[@]}"; do
                rm "$file"
                echo "Deleted $file"
            done
        fi
       ;;
    -q)
        lsofFile=$(checkLsof yes)  # Collecting the filename from checkLsof
        OpenPortsFile=$(listOpenPorts yes)  # Collecting the filename from listOpenPorts
        DiskUtilizationFile=$(showDiskUtilization yes)  # Collection the filename from showDiskUtilization
        LoadStatsFile=$(showLoadStats yes)  # Collecting the load stats from showLoadStats
        MemoryUtilizationFile=$(showMemoryUtilization yes)  # Collecting the memory utilization from MemoryUtilizationFile
        NetstatConnectionsFile=$(showNetstatConnections yes)  # Collecting the netstat details from showNetstatConnections
        ProcessesWithThreadsFile=$(showProcessesWithThreads yes)  # Collecting the processes & threads from showProcessesWithThreads
        tcpdumpFile=$(performTcpdump yes)  # Collecting the filename from performTcpdump
        TomcatThreadDumpFile=$(performTomcatThreadDump yes)  # Collecting the filename from performTomcatThreadDump

        # Create an array to hold all filenames
        outputFiles=($lsofFile $OpenPortsFile $DiskUtilizationFile $LoadStatsFile $MemoryUtilizationFile $NetstatConnectionsFile $ProcessesWithThreadsFile $tcpdumpFile $TomcatThreadDumpFile)

        tar -czvf "diagnostics_$(hostname)_$(date +%Y%m%d%H%M%S).tar.gz" "${outputFiles[@]}"
        for file in "${outputFiles[@]}"; do
            rm "$file"
        done
        ;;
    *)
        # Show the menu if no specific flags or unrecognized flags are provided.
        showMenu
        ;;
esac