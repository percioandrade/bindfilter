#!/bin/bash
# Author: Percio Andrade - percio.castelo@suporte.m3solutions.com.br
# Description: Filters known domains in Bind9 to prevent DNS spoofing and DNS hijacking

# Define Variables
SRC_VERSION="1.1"
SCRIPT_URL="https://raw.githubusercontent.com/percioandrade/bindfilter/refs/heads/main/bind_filter.sh"
BIND_CONFIG="/etc/bind/named.conf"
BLOCKED_ZONE="/etc/bind/zones/blockeddomains.db"
BLOCKED_ZONE_URL="https://raw.githubusercontent.com/percioandrade/bindfilter/refs/heads/main/blockeddomains.db"
ACL_CONFIG="/etc/bind/blocked_domain_acl.conf"
ACL_CONFIG_URL="https://raw.githubusercontent.com/percioandrade/bindfilter/refs/heads/main/blocked_domain_acl.conf"
OS_VERSION=$(grep '^NAME=' /etc/os-release | cut -d'"' -f2)

# Check if script is run as root
checkRoot() {
    if [[ $EUID -ne 0 ]]; then
        logError "This script must be run as root"
        exit 1
    fi
}

# Check Named Configuration File
checkNamedFile() {
    if [[ ! -f "$BIND_CONFIG" ]]; then
        logError "Named configuration file $BIND_CONFIG not found."
        exit 1
    fi
}

# Define version of script
defineVersion() {
    CHECK_VERSION=$(curl -s $SCRIPT_URL | grep "SRC_VERSION=" | awk -F"'" '{print $2}')

    if [[ $SRC_VERSION != $CHECK_VERSION ]]; then
        echo "Version $SRC_VERSION outdated..."
    else
        echo $SRC_VERSION
    fi
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
    if ! command -v named &> /dev/null; then
        logError "Bind9 is not installed. Script requires Bind9."
        logError "Do you want to install bind? (yY/nN)"
        read -p "Please choose: " BIND_INSTALL

        if [[ ${BIND_INSTALL,,} == "y" ]]; then

            # OS Release Verification
            if [[ ! -e "/etc/os-release" ]]; then
                logError "Cannot determine OS version."
            fi

            if [[ ${OS_VERSION} == "Ubuntu" ]]; then
                apt install -y bind9
            else
                yum install -y bind
            fi
                
        else
            logMessage "Installation skipped. Exiting..."
            exit 1
        fi
    fi
    logMessage "Bind9 found. Continuing..."
}

# Check Directory Existence
checkDirExists() {
    local dir="/etc/bind/zones/"
    if [[ ! -d "$dir" ]]; then
        logMessage "Creating directory $dir..."
        mkdir -p "$dir" || {
            logError "Failed to create directory $dir"
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
    local missing_files=()
    [[ ! -f "$BLOCKED_ZONE" ]] && missing_files+=("$BLOCKED_ZONE")
    [[ ! -f "$ACL_CONFIG" ]] && missing_files+=("$ACL_CONFIG")

    if [[ ${#missing_files[@]} -gt 0 ]]; then
        logMessage "Files not found:"
        for file in "${missing_files[@]}"; do
            logMessage "  - $file"
        done
        return 1
    fi
    return 0
}

# Download Files
downloadBlockedZone() {
    logMessage "Downloading files..."
    curl -s -o "$BLOCKED_ZONE" "$BLOCKED_ZONE_URL" || {
        logError "Failed to download $BLOCKED_ZONE"
        exit 1
    }
}

downloadACLConfig(){
    curl -s -o "$ACL_CONFIG" "$ACL_CONFIG_URL" || {
        logError "Failed to download $ACL_CONFIG"
        exit 1
    }
    logMessage "Download complete."
}

# Add Include Line
addIncludeLine() {
    if ! checkLineExists; then
        logMessage "Adding include line for ACL configuration..."
        echo "include \"$ACL_CONFIG\";" >> "$BIND_CONFIG" || {
            logError "Failed to add include line to $BIND_CONFIG"
            exit 1
        }
    else
        logMessage "Include line already exists in $BIND_CONFIG"
    fi
}

# Restart Named Service
restartNamed() {
    logMessage "Restarting named service..."
    if systemctl restart named; then
        logMessage "Named service restarted successfully."
    else
        logError "Failed to restart named service."
        exit 1
    fi
}

# Parse command-line arguments
parseArgs() {
    case "$1" in
        -r|--run)
            logMessage "Running script..."
            checkBindInstalled	
            checkDirExists
            checkLineExists
            checkFilesExist
            downloadBlockedZone
            downloadACLConfig
            addIncludeLine
            restartNamed
        ;;
        -u|--update)
            if [[ "$2" == "--all" || "$2" == "-a" ]]; then
                logMessage "Updating all files..."
                downloadBlockedZone
            fi
            if [[ "$2" == "--zone" || "$2" == "-z" ]]; then 
                logMessage "Updating Blocked DNS Zone files..."
                downloadBlockedZone
            fi
            if [[ "$2" == "--acl" || "$2" == "-l" ]]; then
                logMessage "Updating ACL Config Zone files..."
                downloadACLConfig
            fi
            ;;
        -c|--check)
            logMessage "Checking if configure is enabled..."
            addIncludeLine
            ;;
        -h|--help)
            showHelp
            ;;
        *)
            logError "Invalid option. Use -h or --help for usage information."
            exit 1
            ;;
    esac
}

# Show help message
showHelp() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -r, --run         run script
    -u, --update      Update files
    --all, -a         Update all files (used with --update)
    --zone -z         Update only blockdnszone
    --acl  -l         Update only acl config
    -c, --check       Check configure line 
    -h, --help        Display this help message

Examples:
    $0 -r --run
    $0 -u                Update specific files
    $0 -u --all          Update all files
    $0 -c                Check Bind installation
EOF
}

# Main Function
main() {
    checkRoot
    checkNamedFile
    osRelease
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