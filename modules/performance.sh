#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../helpers/ui.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../helpers/logging.sh"

tweak_performance() {
    section "PERFORMANCE TWEAKS" "$CYAN"
    
    # Install and configure CPU performance governor
    if yay -S --noconfirm cpupower 2>> "$LOG_FILE"; then
        echo 'GOVERNOR="performance"' | sudo -n tee /etc/default/cpupower
        sudo -n systemctl enable --now cpupower
        log "INFO" "Configured CPU performance governor"
        print_status success "CPU performance governor enabled"
    else
        log "ERROR" "Failed to install cpupower"
        print_status error "Failed to configure CPU governor"
    fi

    # Optimize swappiness for systems with ample RAM
    if [[ $(free -g | awk '/Mem:/ {print $2}') -ge 16 ]]; then
        echo "vm.swappiness=10" | sudo -n tee /etc/sysctl.d/99-swappiness.conf
        log "INFO" "Optimized swappiness for 16GB+ RAM system"
        print_status success "Memory swappiness optimized"
    else
        log "INFO" "Skipping swappiness tweak (RAM < 16GB)"
        print_status info "Skipped swappiness tweak (low RAM)"
    fi
}