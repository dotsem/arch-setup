#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../helpers/ui.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../helpers/logging.sh"

setup_directories() {
    log "INFO" "Creating standard user directories"
    
    local dirs=(
        "$HOME/.config"
        "$HOME/Documents"
        "$HOME/Downloads"
        "$HOME/Music"
        "$HOME/Pictures"
        "$HOME/Videos"
        "$HOME/Desktop"
    )
    
    local failed=0
    
    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            log "INFO" "Directory already exists: $dir"
            continue
        fi
        
        if mkdir -p "$dir"; then
            log "INFO" "Created directory: $dir"
        else
            log "ERROR" "Failed to create directory: $dir"
            failed=$((failed + 1))
        fi
    done
    
    if [ "$failed" -eq 0 ]; then
        echo -e "${GREEN}Directories created successfully!${NC}"
        return 0
    else
        echo -e "${RED}Failed to create $failed directories${NC}"
        return 1
    fi
}

setup_git() {
    log "INFO" "Setting up Git configuration"
    
    if [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL" ]; then
        log "ERROR" "Git configuration missing - need GIT_NAME and GIT_EMAIL"
        echo -e "${RED}Error: GIT_NAME and GIT_EMAIL must be set${NC}"
        return 1
    fi
    
    if git config --global user.name "$GIT_NAME" && \
       git config --global user.email "$GIT_EMAIL"; then
        log "INFO" "Git configured for $GIT_NAME <$GIT_EMAIL>"
        echo -e "${GREEN}Git configured successfully!${NC}"
        return 0
    else
        log "ERROR" "Failed to configure Git"
        echo -e "${RED}Failed to configure Git!${NC}"
        return 1
    fi
}

clone_dotfiles() {
    if [ -z "$DOTFILES_URL" ]; then
        log "WARN" "No DOTFILES_URL specified, skipping dotfiles setup"
        echo -e "${YELLOW}Skipping dotfiles setup (no URL specified)${NC}"
        return 0
    fi
    
    log "INFO" "Cloning dotfiles from $DOTFILES_URL"
    local dotfiles_dir="$HOME/.config"
    
    if [ -d "$dotfiles_dir" ]; then
        # Remove existing dotfiles
        if rm -rf "$dotfiles_dir"; then
            log "INFO" "Removed existing dotfiles at $dotfiles_dir"
        else
            log "ERROR" "Failed to remove existing dotfiles at $dotfiles_dir"
            echo -e "${RED}Failed to remove existing dotfiles!${NC}"
            return 1
        fi
    fi
    
    if git clone "$DOTFILES_URL" "$dotfiles_dir"; then
        if [ -d "$dotfiles_dir" ]; then
            if rsync -a "$dotfiles_dir/" "$HOME/.config/" && \
               rm -rf "$dotfiles_dir"; then
                log "INFO" "Dotfiles successfully installed"
                echo -e "${GREEN}Dotfiles installed successfully!${NC}"
                return 0
            else
                log "ERROR" "Failed to sync dotfiles to .config"
                echo -e "${RED}Error installing dotfiles!${NC}"
                return 1
            fi
        else
            log "ERROR" "Dotfiles directory missing after clone"
            echo -e "${RED}Error: Dotfiles directory not found after clone${NC}"
            return 1
        fi
    else
        log "ERROR" "Failed to clone dotfiles repository"
        echo -e "${RED}Failed to clone dotfiles!${NC}"
        return 1
    fi

    ln -s /home/sem/.config/hypr/background-changer/img /home/sem/Pictures/img
}


setup_network() {
    section "NETWORK CONFIGURATION" "$BLUE"
    log "INFO" "Configuring NetworkManager"
    
    # Enable and start NetworkManager
    if sudo -n systemctl enable --now NetworkManager 2>> "$LOG_FILE"; then
        log "INFO" "NetworkManager enabled and started"
        echo -e "${GREEN}NetworkManager configured!${NC}"
        return 0
    else
        log "ERROR" "Failed to enable NetworkManager"
        echo -e "${RED}Failed to configure NetworkManager!${NC}"
        return 1
    fi
}

setup_moncon() {
    # only works when a valid moncon is already pressent
    sh $HOME/.config/hypr/hyprmoncon/hyprmoncon.sh
}

setup_ly() {
    log "INFO" "Setting up ly display manager"
        
    # Disable any existing display managers to avoid conflicts
    local display_managers=("gdm" "sddm" "lightdm" "lxdm" "slim")
    for dm in "${display_managers[@]}"; do
        if systemctl is-enabled "$dm" &>/dev/null; then
            log "INFO" "Disabling conflicting display manager: $dm"
            sudo -n systemctl disable "$dm" 2>/dev/null || true
        fi
    done
    
    # Enable and start ly service
    if sudo -n systemctl enable --now ly.service; then
        log "INFO" "Successfully enabled and started ly service"
        echo -e "${GREEN}ly display manager enabled and started!${NC}"
        return 0
    else
        log "ERROR" "Failed to enable ly service"
        echo -e "${RED}Failed to enable ly service!${NC}"
        return 1
    fi
}



