#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../helpers/ui.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../helpers/logging.sh"

setup_ui_enhancements() {
    section "UI ENHANCEMENTS" "$YELLOW"
    
    # Install Neovim (suppress warnings)
    yay -S --noconfirm neovim 2>/dev/null || {
        log "ERROR" "Neovim installation failed"
        print_status error "Neovim installation failed"
        return 1
    }

    # Parallel plugin setup
    nvim_dir="$HOME/.local/share/nvim/site/pack/packer/start/packer.nvim"
    if [ ! -d "$nvim_dir" ]; then
        print_status info "Installing plugin manager..."
        git clone --depth 1 --single-branch https://github.com/wbthomason/packer.nvim "$nvim_dir" 2>> "$LOG_FILE" &
        pid=$!
        
        # Show spinner during clone
        spinner $pid "Cloning packer.nvim"
        
        if wait $pid; then
            print_status success "Plugin manager installed"
        else
            log "ERROR" "Failed to clone packer.nvim"
            print_status error "Plugin manager installation failed"
            return 1
        fi
    fi

    # Background plugin sync with progress
    print_status info "Syncing plugins in background (check later with :PackerStatus)"
    nohup bash -c 'nvim --headless -c "autocmd User PackerComplete quitall" -c "PackerSync"' >/dev/null 2>> "$LOG_FILE" &
    
    check_nvim_plugins
    return 0
}


check_nvim_plugins() {
    if [ -d "$HOME/.local/share/nvim/site/pack/packer/opt" ]; then
        print_status success "Neovim plugins installed"
    else
        print_status info "Run ':PackerSync' in Neovim to complete plugin setup"
    fi
}