#!/bin/bash

# Script Information
# Author: Percio Andrade - percio.castelo@suporte.m3solutions.com.br
# Description: Filters known domains in Bind9 to prevent DNS spoofing and DNS hijacking
# Version: 1.1
# Last Updated: 2023-06-14

# Define Variables
BIND_CONFIG="/etc/bind/named.conf"
BLOCKED_ZONE="/etc/bind/zones/blockeddomains.db"
BLOCKED_ZONE_URL="http://tote.m3solutions.net.br/images/c/c6/Blockeddomains.db"
ACL_CONFIG="/etc/bind/blocked_domain_acl.conf"
ACL_CONFIG_URL="http://tote.m3solutions.net.br/images/1/10/Blocked_domain_acl.conf"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to log errors
log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
}

# Check if script is run as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Check Bind Installation
check_bind_installed() {
    if ! command -v named &> /dev/null; then
        log_error "Bind9 is not installed. Script requires Bind9."
        exit 1
    fi
    log_message "Bind9 found. Continuing..."
}

# Check Directory Existence
check_dir_exists() {
    local dir="/etc/bind/zones/"
    if [[ ! -d "$dir" ]]; then
        log_message "Creating directory $dir..."
        mkdir -p "$dir" || {
            log_error "Failed to create directory $dir"
            exit 1
        }
    fi
}

# Check Named Configuration File
check_named_file() {
    if [[ ! -f "$BIND_CONFIG" ]]; then
        log_error "Named configuration file $BIND_CONFIG not found."
        exit 1
    fi
}

# Check Line Existence
check_line_exists() {
    grep -q "include \"$ACL_CONFIG\";" "$BIND_CONFIG"
}

# Check File Existence
check_files_exist() {
    local missing_files=()
    [[ ! -f "$BLOCKED_ZONE" ]] && missing_files+=("$BLOCKED_ZONE")
    [[ ! -f "$ACL_CONFIG" ]] && missing_files+=("$ACL_CONFIG")
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        log_message "Files not found:"
        for file in "${missing_files[@]}"; do
            log_message "  - $file"
        done
        return 1
    fi
    return 0
}

# Download Files
download_files() {
    log_message "Downloading files..."
    curl -s -o "$BLOCKED_ZONE" "$BLOCKED_ZONE_URL" || {
        log_error "Failed to download $BLOCKED_ZONE"
        exit 1
    }
    curl -s -o "$ACL_CONFIG" "$ACL_CONFIG_URL" || {
        log_error "Failed to download $ACL_CONFIG"
        exit 1
    }
    log_message "Download complete."
}

# Add Include Line
add_include_line() {
    if ! check_line_exists; then
        log_message "Adding include line for ACL configuration..."
        echo "include \"$ACL_CONFIG\";" >> "$BIND_CONFIG" || {
            log_error "Failed to add include line to $BIND_CONFIG"
            exit 1
        }
    else
        log_message "Include line already exists in $BIND_CONFIG"
    fi
}

# Restart Named Service
restart_named() {
    log_message "Restarting named service..."
    if systemctl restart named; then
        log_message "Named service restarted successfully."
    else
        log_error "Failed to restart named service."
        exit 1
    fi
}

# Main Script Flow
main() {
    check_root
    check_bind_installed
    check_named_file
    check_dir_exists

    if check_files_exist; then
        read -p "Update existing files? (y/n) " answer
        if [[ "$answer" != "y" ]]; then
            log_message "Exiting..."
            exit 0
        fi
    fi

    download_files
    add_include_line

    log_message "Bind9 configuration updated with domain filtering."
    restart_named
}

# Run the main function
main
