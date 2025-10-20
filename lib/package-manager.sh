#!/bin/bash
# Package Installation Functions
# Handles installation logic for different package managers

source "$(dirname "${BASH_SOURCE[0]}")/../helpers/ui.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../helpers/logging.sh"

# Install a single package with retry logic
install_package() {
    local installer="$1"
    local package="$2"
    local max_attempts="${3:-2}"

    for attempt in $(seq 1 $max_attempts); do
        log "INFO" "Installation attempt $attempt/$max_attempts for $package"

        case $installer in
            pacman)
                if sudo -n pacman -S --noconfirm --needed "$package" 2>> "$LOG_FILE"; then
                    log "INFO" "Successfully installed $package via pacman"
                    return 0
                else
                    log "WARN" "Attempt $attempt failed for $package (pacman)"
                fi
                ;;
            yay)
                if yay -S --noconfirm --needed "$package" 2>> "$LOG_FILE"; then
                    log "INFO" "Successfully installed $package via yay"
                    return 0
                else
                    log "WARN" "Attempt $attempt failed for $package (yay)"
                fi
                ;;
            flatpak)
                if flatpak install -y flathub "$package" 2>> "$LOG_FILE"; then
                    log "INFO" "Successfully installed $package via Flatpak"
                    return 0
                else
                    log "WARN" "Attempt $attempt failed for $package (Flatpak)"
                fi
                ;;
        esac
        
        # Wait before retry (except on last attempt)
        if [ $attempt -lt $max_attempts ]; then
            sleep 2
        fi
    done

    log "ERROR" "All installation attempts failed for $package"
    return 1
}

# Install yay AUR helper
install_yay() {
    section "Installing YAY AUR Helper" "$GREEN"
    log "INFO" "Starting YAY installation"

    if command -v yay &>/dev/null; then
        log "INFO" "YAY already installed"
        echo -e "${GREEN}Yay already installed!${NC}"
        return 0
    fi

    log "DEBUG" "Installing YAY dependencies"
    sudo -n pacman -S --needed --noconfirm git base-devel || {
        log "ERROR" "Failed to install YAY dependencies"
        return 1
    }

    rm -rf /tmp/yay
    log "INFO" "Cloning YAY repository"
    
    if ! git clone https://aur.archlinux.org/yay.git /tmp/yay 2>> "$LOG_FILE"; then
        log "ERROR" "Failed to clone YAY repo"
        return 1
    fi

    cd /tmp/yay
    
    if [ "$(id -u)" -eq 0 ]; then
        log "ERROR" "makepkg should NOT be run as root. Aborting YAY build."
        cd - >/dev/null
        return 1
    fi

    log "INFO" "Building YAY package"
    if makepkg -si --noconfirm 2>> "$LOG_FILE"; then
        cd - >/dev/null
        log "INFO" "YAY installed successfully"
        echo -e "${GREEN}Yay installed successfully!${NC}"
        return 0
    else
        log "ERROR" "YAY build failed"
        cd - >/dev/null
        return 1
    fi
}

# Setup Flatpak and Flathub
setup_flatpak() {
    section "Setting up Flatpak" "$BLUE"
    log "INFO" "Installing Flatpak if missing"
    
    sudo -n pacman -S --needed --noconfirm flatpak || {
        log "ERROR" "Failed to install Flatpak"
        return 1
    }

    if ! flatpak remotes | grep -q flathub; then
        log "INFO" "Adding Flathub remote"
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        echo -e "${GREEN}Flathub remote added!${NC}"
    else
        log "INFO" "Flathub already configured"
        echo -e "${GREEN}Flathub already configured!${NC}"
    fi
    
    return 0
}

# Install packages from an array
install_package_array() {
    local installer="$1"
    shift
    local packages=("$@")
    local failed=0
    local failed_packages=()
    
    for pkg in "${packages[@]}"; do
        if ! install_package "$installer" "$pkg"; then
            ((failed++))
            failed_packages+=("$pkg")
        fi
    done
    
    if [ $failed -gt 0 ]; then
        log "WARN" "$failed packages failed to install via $installer"
        return 1
    fi
    
    return 0
}

# Detect and add NVIDIA drivers to package list
detect_and_add_nvidia() {
    local -n pkg_array=$1
    
    if lspci | grep -qi nvidia; then
        log "INFO" "NVIDIA GPU detected, adding drivers"
        
        # Check if nvidia is already in the array
        local has_nvidia=false
        for pkg in "${pkg_array[@]}"; do
            if [[ "$pkg" == "nvidia" ]]; then
                has_nvidia=true
                break
            fi
        done
        
        if ! $has_nvidia; then
            pkg_array+=(nvidia nvidia-utils nvidia-settings)
            log "INFO" "Added NVIDIA packages to installation list"
        fi
    fi
}
