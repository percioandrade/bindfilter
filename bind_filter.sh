#!/bin/bash
# Author: Percio Andrade - percio@zendev.com.br|perciocastelo@gmail.com
# Description: Filters known domains in Bind9 to prevent DNS spoofing and DNS hijacking

# Define Variables
SCRIPT_SRC_VERSION="1.2"
SCRIPT_URL="https://raw.githubusercontent.com/percioandrade/bindfilter/refs/heads/main/bind_filter.sh"
BLOCKED_ZONE="/etc/bind/zones/blockeddomains.db"
BLOCKED_ZONE_URL="https://raw.githubusercontent.com/percioandrade/bindfilter/refs/heads/main/blockeddomains.db"
ACL_CONFIG="/etc/bind/blocked_domain_acl.conf"
ACL_CONFIG_URL="https://raw.githubusercontent.com/percioandrade/bindfilter/refs/heads/main/blocked_domain_acl.conf"
OS_VERSION=$(grep '^NAME=' /etc/os-release | cut -d'"' -f2)
REMOTE_VERSION=$(curl -s "$SCRIPT_URL" | grep -o 'SCRIPT_SRC_VERSION="[^"]*"' | awk -F'"' '{print $2}')

# text
LOG_NOT_ROOT="This script must be run as root."
ERROR_BIND_NOT_INSTALLED="Bind9 is not installed. Please install it to proceed."
LOG_LOCATED_NAMED_CONF="Found named configuration file: $file"
LOG_NOT_LOCATED_NAMED_CONF="Named configuration file not found."
LOG_VERSION_OUTDATED="Local version ($SCRIPT_SRC_VERSION) is outdated. Remote version: ($REMOTE_VERSION)."
LOG_VERSION_UPDATED="Script is up-to-date (version: $SCRIPT_SRC_VERSION)."
LOG_FILES_NOT_FOUND="Files not found:"
LOG_FILES_NOT_CREATED="Failed to create directory"
LOG_FAILED_DOWNLOAD="Failed to download"
LOG_RESTART_NAMED="Restarting named service..."
LOG_RESTART_SUCCESS="Named service restarted successfully."
LOG_RESTART_FAILED="Failed to restart named service."
LOG_ADDING_INCLUDE="Adding include line for ACL configuration..."
LOG_INCLUDE_EXISTS="Include line already exists"
LOG_UPDATE_FILES="Updating files..."
LOG_UPDATE_FILES_ZONES="Zone file downloader"
LOG_UPDATE_FILES_ACL="ACL file downloader"
LOG_INSTALL_BIND="Do you want to install bind? (yY/nN)"
LOG_BIND_FOUND="Bind9 found. Continuing..."
LOG_PACKAGE_MANAGER="Unsupported package manager. Please install $package manually."
LOG_CREATING_DIR="Creating directory $dir..."
LOG_DOWNLOAD_COMPLETE="Download complete."
LOG_FAILED_INCLUDE="Failed to add include line to $BIND_CONFIG"

# Check if script is run as root
checkRoot() {
    if [[ $EUID -ne 0 ]]; then
        logError "$LOG_NOT_ROOT"
        exit 1
    fi
}

defineVersion() {
    if [[ "$SCRIPT_SRC_VERSION" != "$REMOTE_VERSION" ]]; then
        echo "$LOG_VERSION_OUTDATED"
    else
        echo "$LOG_VERSION_UPDATED"
    fi
}

# Check Named Configuration File
checkNamedFile() {
    local files=("/etc/bind/named.conf" "/etc/named.conf")
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            logMessage "$LOG_LOCATED_NAMED_CONF"
            BIND_CONFIG="$file"
            return 0
        fi
    done
    logError "$LOG_NOT_LOCATED_NAMED_CONF"
    exit 1
}

# Function to log messages
logMessage() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to log errors
logError() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
}

# Check Bind Installation
checkBindInstalled() {
    if ! bind -v named &> /dev/null; then
        logError "$ERROR_BIND_NOT_INSTALLED"
        logError "$LOG_INSTALL_BIND"
        read -p "Please choose: " BIND_INSTALL
        local package="$1"
        if command -v apt >/dev/null; then
            apt update && apt install -y "$package"
        elif command -v yum >/dev/null; then
            yum install -y "$package"
        else
            logError "$LOG_PACKAGE_MANAGER"
            exit 1
        fi
    fi
    logMessage "$LOG_BIND_FOUND"
}

# Check Directory Existence
checkDirExists() {
    local dir="/etc/bind/zones/"
    if [[ ! -d "$dir" ]]; then
        logMessage "$LOG_CREATING_DIR..."
        mkdir -p "$dir" || {
            logError "$LOG_FILES_NOT_CREATED $dir"
            exit 1
        }
    fi
}

# Check Line Existence
checkLineExists() {
    grep -q "include \"$ACL_CONFIG\";" "$BIND_CONFIG"
}

# Check File Existence
checkFilesExist() {
    local MISSING_FILES=()
    [[ ! -f "$BLOCKED_ZONE" ]] && MISSING_FILES+=("$BLOCKED_ZONE")
    [[ ! -f "$ACL_CONFIG" ]] && MISSING_FILES+=("$ACL_CONFIG")

    if [[ ${#MISSING_FILES[@]} -gt 0 ]]; then
        logMessage "$LOG_FILES_NOT_FOUND"
        for file in "${MISSING_FILES[@]}"; do
            logMessage "  - $file"
        done
        return 1
    fi
    return 0
}

# Download Files
downloadBlockedZone() {
    logMessage "$LOG_UPDATE_FILES"
    curl -s -o "$BLOCKED_ZONE" "$BLOCKED_ZONE_URL" || {
        logError "$LOG_FAILED_DOWNLOAD $BLOCKED_ZONE"
        exit 1
    }
}

# Download ACL
downloadACLConfig(){
    curl -s -o "$ACL_CONFIG" "$ACL_CONFIG_URL" || {
        logError "$LOG_FAILED_DOWNLOAD $ACL_CONFIG"
        exit 1
    }
    logMessage "$LOG_DOWNLOAD_COMPLETE"
}

# Add Include Line
addIncludeLine() {
    if ! checkLineExists; then
        logMessage "$LOG_ADDING_INCLUDE"
        echo "include \"$ACL_CONFIG\";" >> "$BIND_CONFIG" || {
            logError "$LOG_FAILED_INCLUDE"
            exit 1
        }
    else
        logMessage "$LOG_INCLUDE_EXISTS"
    fi
}

# Restart Named Service
restartNamed() {
    logMessage "$LOG_RESTART_NAMED"
    if systemctl restart named; then
        logMessage "$LOG_RESTART_SUCCESS"
    else
        logError "$LOG_RESTART_FAILED"
        exit 1
    fi
}

# Parse
# Parse
parseArgs() {
    while getopts "ru:a:lch" opt; do
        case "$opt" in
            r) ACTION="run"
                checkNamedFile
                checkBindInstalled
                checkDirExists
                checkLineExists
                checkFilesExist
                downloadBlockedZone
                downloadACLConfig
                addIncludeLine
                restartNamed
            ;;
            u) ACTION="update"; TARGET="$OPTARG" 
                # Check if -z or -a is passed after -u
                case "$TARGET" in
                    -z) logMessage "$LOG_UPDATE_FILES_ZONES"
                        downloadBlockedZone
                    ;;
                    -a) 
                        logMessage "$LOG_UPDATE_FILES_ACL"
                        downloadACLConfig
                    ;;
                    --all) 
                        logMessage "$LOG_UPDATE_FILES_ZONES"
                        downloadBlockedZone
                        logMessage "$LOG_UPDATE_FILES_ACL"
                        downloadACLConfig
                    ;;
                    *) 
                        echo "Invalid target for update: $TARGET"
                        showHelp
                        exit 1
                    ;;
                esac
            ;;
            c) ACTION="check"
                checkNamedFile
                checkBindInstalled
                checkDirExists
                checkLineExists
                checkFilesExist
                addIncludeLine
            ;;
            h) showHelp; exit 0 ;;
            *) logError "Invalid option"; showHelp; exit 1 ;;
        esac
    done
}


# Show help message
showHelp() {
    cat << EOF
Usage: $0 [OPTIONS]

OPTIONS:
  -r, --run             Run the script to apply DNS filters.
  -u, --update [TARGET] Update files. Targets:
                        all   - Update all files
                        zone  - Update blocked DNS zones
                        acl   - Update ACL configuration
  -c, --check           Verify if Bind is properly configured.
  -h, --help            Show this help message.

EXAMPLES:
  $0 -r                Run the script
  $0 -u all            Update all files
  $0 -c                Check Bind installation
EOF
}

# Main Function
main() {
    checkRoot
    if [[ $# -eq 0 ]]; then
        showHelp
        exit 0
    fi
    parseArgs "$@"
}

# Execute Main Function
echo -e "
 ______ __           __ _______ __ __ __              
|   __ \__|.-----.--|  |    ___|__|  |  |_.-----.----.
|   __ <  ||     |  _  |    ___|  |  |   _|  -__|   _|
|______/__||__|__|_____|___|   |__|__|____|_____|__|  
Version: `defineVersion`
"

main "$@"
