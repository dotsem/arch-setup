#!/bin/bash
# Flutter and Kolibri Shell Setup Module

source "$(dirname "${BASH_SOURCE[0]}")/../helpers/ui.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../helpers/logging.sh"

setup_flutter_environment() {
    section "FLUTTER ENVIRONMENT SETUP" "$MAGENTA"
    log "INFO" "Setting up Flutter development environment"
    
    # Check if flutter is installed
    if ! command -v flutter &>/dev/null; then
        log "ERROR" "Flutter is not installed. Install it via AUR (flutter or flutter-bin)"
        print_status error "Flutter not found"
        return 1
    fi
    
    # Accept Android licenses
    print_status info "Accepting Android licenses..."
    if yes | flutter doctor --android-licenses 2>> "$LOG_FILE"; then
        log "INFO" "Android licenses accepted"
        print_status success "Android licenses accepted"
    else
        log "WARN" "Failed to accept Android licenses (may require manual intervention)"
        print_status warning "Android licenses may need manual acceptance"
    fi
    
    # Run flutter doctor to check setup
    print_status info "Running Flutter doctor..."
    flutter doctor -v 2>&1 | tee -a "$LOG_FILE"
    
    log "INFO" "Flutter environment setup completed"
    print_status success "Flutter environment ready"
    return 0
}

setup_kolibri_shell() {
    section "KOLIBRI SHELL SETUP" "$MAGENTA"
    log "INFO" "Setting up Kolibri Shell taskbar"
    
    local kolibri_dir="$HOME/.local/share/kolibri-shell"
    local kolibri_repo="https://github.com/dotsem/kolibri-shell.git"
    
    # Ensure Flutter is available
    if ! command -v flutter &>/dev/null; then
        log "ERROR" "Flutter is required for Kolibri Shell"
        print_status error "Flutter not available - install Flutter first"
        return 1
    fi
    
    # Clone or update repository
    if [ -d "$kolibri_dir" ]; then
        log "INFO" "Kolibri Shell already exists, updating..."
        print_status info "Updating Kolibri Shell..."
        cd "$kolibri_dir"
        if git pull origin main 2>> "$LOG_FILE"; then
            log "INFO" "Kolibri Shell updated"
        else
            log "WARN" "Failed to update Kolibri Shell"
            cd - > /dev/null
            return 1
        fi
        cd - > /dev/null
    else
        log "INFO" "Cloning Kolibri Shell from $kolibri_repo"
        print_status info "Cloning Kolibri Shell..."
        
        mkdir -p "$(dirname "$kolibri_dir")"
        if git clone "$kolibri_repo" "$kolibri_dir" 2>> "$LOG_FILE"; then
            log "INFO" "Kolibri Shell cloned successfully"
            print_status success "Kolibri Shell cloned"
        else
            log "ERROR" "Failed to clone Kolibri Shell"
            print_status error "Failed to clone Kolibri Shell"
            return 1
        fi
    fi
    
    # Build Kolibri Shell
    log "INFO" "Building Kolibri Shell (this may take a while)..."
    print_status info "Building Kolibri Shell... (please wait)"
    
    cd "$kolibri_dir"
    if flutter pub get 2>> "$LOG_FILE" && \
       flutter build linux --release 2>> "$LOG_FILE"; then
        log "INFO" "Kolibri Shell built successfully"
        print_status success "Kolibri Shell built successfully"
        
        # Create symlink for easy access
        local bin_dir="$HOME/.local/bin"
        mkdir -p "$bin_dir"
        
        local executable="$kolibri_dir/build/linux/x64/release/bundle/kolibri_shell"
        local symlink="$bin_dir/kolibri-shell"
        
        if [ -f "$executable" ]; then
            ln -sf "$executable" "$symlink"
            log "INFO" "Created symlink at $symlink"
            print_status success "Kolibri Shell ready to use"
            echo -e "${GREEN}Run 'kolibri-shell' to start the taskbar${NC}"
        else
            log "ERROR" "Executable not found at expected location"
            print_status error "Build completed but executable not found"
            cd - > /dev/null
            return 1
        fi
        
        cd - > /dev/null
        return 0
    else
        log "ERROR" "Failed to build Kolibri Shell"
        print_status error "Build failed"
        cd - > /dev/null
        return 1
    fi
}
