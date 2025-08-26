#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../helpers/ui.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../helpers/logging.sh"

setup_zsh() {
    local usb_zshrc="${USB_MOUNT_PATH}/.zshrc"
    local home_zshrc="$HOME/.zshrc"
    
    # Copy .zshrc from USB if available
    if [ -n "$USB_MOUNT_PATH" ] && [ -f "$usb_zshrc" ]; then
        log "INFO" "Copying .zshrc from USB"
        
        if cp "$usb_zshrc" "$home_zshrc"; then
            log "INFO" "Successfully copied .zshrc from USB"
            echo -e "${GREEN}Copied .zshrc from USB!${NC}"
        else
            log "ERROR" "Failed to copy .zshrc from USB"
            echo -e "${RED}Failed to copy .zshrc from USB${NC}"
        fi
    else
        log "WARN" "No .zshrc found at USB location"
        echo -e "${YELLOW}No .zshrc found at USB location${NC}"
    fi
    
    # Install Oh My Zsh if not present
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log "INFO" "Installing Oh My Zsh"
        echo -e "${YELLOW}Installing Oh My Zsh...${NC}"
        
        if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; then
            log "INFO" "Oh My Zsh installed successfully"
            echo -e "${GREEN}Oh My Zsh installed!${NC}"
        else
            log "ERROR" "Failed to install Oh My Zsh"
            echo -e "${RED}Failed to install Oh My Zsh${NC}"
            return 1
        fi
    else
        log "INFO" "Oh My Zsh already installed"
        echo -e "${GREEN}Oh My Zsh already installed${NC}"
    fi
    
    # Set Zsh as default shell
    if ! command -v zsh >/dev/null 2>&1; then
        log "ERROR" "Zsh not installed"
        echo -e "${RED}Zsh not installed - cannot set as default shell${NC}"
        return 1
    fi
    
    local current_shell=$(getent passwd "$USER" | cut -d: -f7)
    local zsh_path=$(which zsh)
    
    if [ "$current_shell" = "$zsh_path" ]; then
        log "INFO" "Zsh is already the default shell"
        echo -e "${GREEN}Zsh is already the default shell${NC}"
        return 0
    fi
    
    log "INFO" "Setting Zsh as default shell"
    if sudo -n chsh -s "$zsh_path" "$USER"; then
        log "INFO" "Successfully set Zsh as default shell"
        echo -e "${GREEN}Zsh set as default shell!${NC}"
        echo -e "${YELLOW}Note: Log out required for changes to take effect${NC}"
        return 0
    else
        log "ERROR" "Failed to set Zsh as default shell"
        echo -e "${RED}Failed to set Zsh as default shell${NC}"
        return 1
    fi
}

setup_zsh_plugins() {
    section "Configuring Zsh Plugins" "$YELLOW"
    
    local plugins=(
        "zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions"
        "zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting"
    )
    
    for plugin in "${plugins[@]}"; do
        local name=${plugin%% *}
        local url=${plugin#* }
        local target_dir="$HOME/.oh-my-zsh/custom/plugins/$name"
        
        if [ ! -d "$target_dir" ]; then
            log "INFO" "Installing plugin: $name"
            if git clone "$url" "$target_dir" 2>> "$LOG_FILE"; then
                log "INFO" "Successfully installed $name"
                echo -e "${GREEN}Installed: $name${NC}"
            else
                log "ERROR" "Failed to install $name"
                echo -e "${RED}Failed to install: $name${NC}"
            fi
        else
            log "INFO" "Plugin already exists: $name"
            echo -e "${YELLOW}$name already installed${NC}"
        fi
    done
    
    # Update .zshrc if plugins aren't configured
    if ! grep -q "zsh-autosuggestions" ~/.zshrc || \
       ! grep -q "zsh-syntax-highlighting" ~/.zshrc; then
        log "INFO" "Updating .zshrc plugins"
        sed -i '/^plugins=(/ {
            /zsh-autosuggestions/! s/)/ zsh-autosuggestions)/
            /zsh-syntax-highlighting/! s/)/ zsh-syntax-highlighting)/
        }' ~/.zshrc
        echo -e "${GREEN}Updated .zshrc plugins${NC}"
    fi
}
