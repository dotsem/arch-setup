#!/bin/bash

# UI Functions
source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

# Section headers
section() {
    echo -e "\n$2=============================="
    echo -e " $1"
    echo -e "==============================${NC}"
}

print_status() {
    case "$1" in
        success) echo -e "${GREEN}[✓] $2${NC}" ;;
        error)   echo -e "${RED}[✗] $2${NC}" ;;
        info)    echo -e "${BLUE}[i] $2${NC}" ;;
    esac
}

# Helper function for spinner animation
spinner() {
    local pid=$1
    local msg=$2
    local delay=0.25
    local spinstr='|/-\'
    
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c] %s " "$spinstr" "$msg"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}