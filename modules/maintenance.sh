#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../helpers/ui.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../helpers/logging.sh"

setup_maintenance() {
    section "SYSTEM MAINTENANCE" "$CYAN"
    
    # Enable weekly SSD trimming
    if sudo -n systemctl enable --now fstrim.timer 2>> "$LOG_FILE"; then
        log "INFO" "Enabled SSD trimming service"
        print_status success "Automatic SSD trimming enabled"
    else
        log "ERROR" "Failed to enable SSD trimming"
        print_status error "Failed to enable SSD trimming"
    fi

    # Set up automatic package cache cleaning
    if yay -S --noconfirm pacman-contrib 2>> "$LOG_FILE"; then
        sudo -n systemctl enable --now paccache.timer
        log "INFO" "Configured package cache cleaning"
        print_status success "Automatic package cache cleaning enabled"
    else
        log "ERROR" "Failed to install pacman-contrib"
        print_status error "Failed to setup package cache cleaning"
    fi

    # Configure systemd journal log limits
    sudo -n sed -i 's/^#SystemMaxUse=/SystemMaxUse=100M/' /etc/systemd/journald.conf
    log "INFO" "Configured journal log limits"
    print_status info "Journal logs limited to 100MB"
}