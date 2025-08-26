#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../helpers/ui.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../helpers/logging.sh"

setup_cloud() {
    section "CLOUD STORAGE" "$BLUE"
    
    if yay -S --noconfirm rclone 2>> "$LOG_FILE"; then
        mkdir -p ~/GoogleDrive
        log "INFO" "Rclone installed - manual config needed"
        print_status info "Run 'rclone config' to set up Google Drive"
        
        # Add mount helper to zshrc
        echo -e "\n# Rclone Google Drive mount\nalias gdrive='rclone mount --vfs-cache-mode full gdrive: ~/GoogleDrive &'" >> ~/.zshrc
        print_status success "Google Drive alias configured"
    else
        log "ERROR" "Failed to install Rclone"
        print_status error "Cloud setup failed"
    fi
}