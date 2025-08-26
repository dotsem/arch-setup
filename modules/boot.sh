#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../helpers/ui.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../helpers/logging.sh"

setup_boot() {
    section "BOOT CUSTOMIZATION" "$WHITE"
    local errors=0

    # 1. Configure NVIDIA KMS support (if NVIDIA GPU detected)
    if lspci | grep -qi nvidia; then
        log "INFO" "NVIDIA GPU detected - configuring KMS support"
        local current_modules=$(grep "^MODULES=" /etc/mkinitcpio.conf | cut -d'=' -f2 | tr -d '()')
        if [[ -n "$current_modules" ]]; then
            if ! echo "$current_modules" | grep -q "nvidia"; then
                sudo -n sed -i "s/^MODULES=($current_modules)/MODULES=($current_modules nvidia nvidia_modeset nvidia_uvm nvidia_drm)/" /etc/mkinitcpio.conf
                log "INFO" "Added NVIDIA modules to mkinitcpio"
            fi
        else
            sudo -n sed -i 's/^MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
            log "INFO" "Added NVIDIA modules to mkinitcpio"
        fi
    fi

    # 2. Configure Kernel Parameters
    configure_kernel_params() {
        local grub_file="/etc/default/grub"
        local boot_entry="/boot/loader/entries/arch.conf"

        if [[ -f "$grub_file" ]]; then
            if lspci | grep -qi nvidia; then
                if ! grep -q "nvidia-drm.modeset=1" "$grub_file"; then
                    sudo -n sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\([^"]*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia-drm.modeset=1"/' "$grub_file"
                    log "INFO" "Added nvidia-drm.modeset=1 to GRUB kernel parameters"
                fi
            fi
            sudo -n grub-mkconfig -o /boot/grub/grub.cfg
            log "INFO" "GRUB configuration updated"
        elif [[ -f "$boot_entry" ]]; then
            if lspci | grep -qi nvidia; then
                if ! grep -q "nvidia-drm.modeset=1" "$boot_entry"; then
                    sudo -n sed -i 's/options \(.*\)/options \1 nvidia-drm.modeset=1/' "$boot_entry"
                    log "INFO" "Added nvidia-drm.modeset=1 to systemd-boot kernel parameters"
                fi
            fi
            log "INFO" "systemd-boot kernel parameters updated"
        else
            log "WARN" "Unknown bootloader - manual kernel param config needed"
        fi
    }
    configure_kernel_params

    # 3. Rebuild initramfs
    log "INFO" "Rebuilding initramfs"
    if sudo -n mkinitcpio -P 2>> "$LOG_FILE"; then
        log "INFO" "Initramfs rebuilt successfully"
    else
        log "ERROR" "Failed to rebuild initramfs"
        print_status error "Initramfs rebuild failed"
        ((errors++))
    fi

    if [[ $errors -eq 0 ]]; then
        print_status success "Boot setup complete - REBOOT to see changes"
    else
        print_status warning "Boot setup completed with $errors errors"
    fi

    return $errors
}
