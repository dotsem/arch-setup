#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../helpers/ui.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../helpers/logging.sh"

setup_security() {
    section "SECURITY SETUP" "$CYAN"
    
    # Install and configure UFW firewall
    if yay -S --noconfirm ufw 2>> "$LOG_FILE"; then
        sudo -n ufw default deny incoming
        sudo -n ufw default allow outgoing
        sudo -n ufw allow OpenSSH
        sudo -n ufw enable
        sudo -n systemctl enable ufw
        log "INFO" "Configured UFW firewall"
        print_status success "Firewall configured (UFW)"
    else
        log "ERROR" "Failed to install UFW"
        print_status error "Firewall setup failed"
    fi

    # Enable automatic security updates
    if ! grep -q "SystemdCron" /etc/pacman.conf; then
        echo "SystemdCron = yes" | sudo -n tee -a /etc/pacman.conf
        log "INFO" "Enabled automatic security updates"
        print_status success "Automatic security updates enabled"
    else
        log "INFO" "Automatic updates already configured"
        print_status info "Automatic updates already active"
    fi
    cleanup_pacman_conf
}

cleanup_pacman_conf() {
    sudo -n sed -i '/SystemdCron/d' /etc/pacman.conf
}