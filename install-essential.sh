#!/bin/bash
# Main Arch Setup Script - Essential Installation Only
# For a fresh Arch Linux installation

set -eo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load configuration and helpers
source "$SCRIPT_DIR/vars.sh"
source "$SCRIPT_DIR/helpers/colors.sh"
source "$SCRIPT_DIR/helpers/logging.sh"
source "$SCRIPT_DIR/helpers/ui.sh"

# Load package lists
source "$SCRIPT_DIR/config/packages-essential.sh"

# Load package management functions
source "$SCRIPT_DIR/lib/package-manager.sh"

# Load module functions
source "$SCRIPT_DIR/modules/setup.sh"
source "$SCRIPT_DIR/modules/grub.sh"
source "$SCRIPT_DIR/modules/audio.sh"
source "$SCRIPT_DIR/modules/python.sh"
source "$SCRIPT_DIR/modules/boot.sh"
source "$SCRIPT_DIR/modules/font.sh"
source "$SCRIPT_DIR/modules/maintenance.sh"
source "$SCRIPT_DIR/modules/neovim.sh"
source "$SCRIPT_DIR/modules/performance.sh"
source "$SCRIPT_DIR/modules/security.sh"
source "$SCRIPT_DIR/modules/zsh.sh"
source "$SCRIPT_DIR/modules/usb.sh"
source "$SCRIPT_DIR/modules/flutter.sh"

# Global error tracking
declare -g ERRORS=0
declare -ga FAILED_STEPS=()

# Add failed step to tracking
track_failure() {
    local step="$1"
    FAILED_STEPS+=("$step")
    ((ERRORS++))
}

# Execute a setup step with error handling
execute_step() {
    local step_name="$1"
    local step_function="$2"
    
    log "INFO" "Executing: $step_name"
    
    if $step_function; then
        log "INFO" "$step_name completed successfully"
        return 0
    else
        log "ERROR" "$step_name failed"
        track_failure "$step_name"
        return 1
    fi
}

# Pre-flight checks
preflight_checks() {
    section "Pre-flight Checks" "$YELLOW"
    
    # Root check
    if [ "$(id -u)" -eq 0 ]; then
        echo -e "${RED}ERROR: Do not run as root!${NC}"
        echo -e "${YELLOW}Run this script as a regular user with sudo privileges.${NC}"
        exit 1
    fi
    
    # Revoke any cached sudo credentials
    sudo -K
    
    # Request sudo access
    echo -e "${YELLOW}Enter your sudo password to begin installation${NC}"
    if ! sudo -v; then
        echo -e "${RED}Authentication failed!${NC}"
        exit 1
    fi
    
    # Start sudo keep-alive
    (
        while true; do
            sudo -n true
            sleep 60
            kill -0 "$$" 2>/dev/null || exit
        done
    ) 2>/dev/null &
    SUDO_KEEPALIVE_PID=$!
    
    # Cleanup on exit
    trap 'sudo -K; kill $SUDO_KEEPALIVE_PID 2>/dev/null; exit' EXIT INT TERM
    
    # Check for pacman lock
    if sudo -n fuser /var/lib/pacman/db.lck >/dev/null 2>&1; then
        echo -e "${RED}ERROR: Pacman database is locked${NC}"
        echo -e "${YELLOW}Another package manager may be running${NC}"
        exit 1
    fi
    
    # Check network
    if ! ping -c 1 -W 5 archlinux.org &>/dev/null; then
        echo -e "${RED}ERROR: No network connectivity${NC}"
        exit 1
    fi
    
    # Check disk space (at least 5GB free)
    local avail_kb=$(df --output=avail "$HOME" | tail -1)
    if [ "$avail_kb" -lt 5000000 ]; then
        echo -e "${RED}ERROR: Insufficient disk space${NC}"
        echo -e "${YELLOW}At least 5GB free space required${NC}"
        exit 1
    fi
    
    # Check critical variables
    if [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL" ]; then
        echo -e "${RED}ERROR: Critical variables missing${NC}"
        echo -e "${YELLOW}Please configure GIT_NAME and GIT_EMAIL in vars.sh${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}All pre-flight checks passed!${NC}\n"
}

# System update
system_update() {
    section "System Update" "$GREEN"
    log "INFO" "Updating system packages"
    
    # Update mirrors on Manjaro
    if command -v pacman-mirrors &>/dev/null; then
        sudo -n pacman-mirrors --fasttrack 2>> "$LOG_FILE" || true
    fi
    
    # Sync and update
    sudo -n pacman -Syy 2>> "$LOG_FILE"
    sudo -n pacman -Syu --noconfirm 2>> "$LOG_FILE"
    
    echo -e "${GREEN}System updated!${NC}"
}

# Install essential packages
install_essential_packages() {
    # Detect and add NVIDIA if needed
    detect_and_add_nvidia ESSENTIAL_PACMAN_PACKAGES
    
    # Add kernel headers for selected kernel
    ESSENTIAL_PACMAN_PACKAGES+=("${KERNEL_TYPE}-headers")
    
    # Install official packages
    section "Installing Essential Packages (Pacman)" "$BLUE"
    local failed_pacman=()
    
    for pkg in "${ESSENTIAL_PACMAN_PACKAGES[@]}"; do
        if ! install_package "pacman" "$pkg"; then
            failed_pacman+=("$pkg")
            track_failure "pacman:$pkg"
        fi
    done
    
    if [ ${#failed_pacman[@]} -gt 0 ]; then
        log "WARN" "${#failed_pacman[@]} pacman packages failed"
    fi
    
    # Install AUR packages
    section "Installing Essential Packages (AUR)" "$YELLOW"
    local failed_aur=()
    
    for pkg in "${ESSENTIAL_AUR_PACKAGES[@]}"; do
        if ! install_package "yay" "$pkg"; then
            failed_aur+=("$pkg")
            track_failure "aur:$pkg"
        fi
    done
    
    if [ ${#failed_aur[@]} -gt 0 ]; then
        log "WARN" "${#failed_aur[@]} AUR packages failed"
    fi
    
    # Install Flatpak packages
    if [ ${#ESSENTIAL_FLATPAK_PACKAGES[@]} -gt 0 ]; then
        section "Installing Essential Packages (Flatpak)" "$MAGENTA"
        local failed_flatpak=()
        
        for pkg in "${ESSENTIAL_FLATPAK_PACKAGES[@]}"; do
            if ! install_package "flatpak" "$pkg"; then
                failed_flatpak+=("$pkg")
                track_failure "flatpak:$pkg"
            fi
        done
        
        if [ ${#failed_flatpak[@]} -gt 0 ]; then
            log "WARN" "${#failed_flatpak[@]} Flatpak packages failed"
        fi
    fi
}

# Configure system
configure_system() {
    section "System Configuration" "$CYAN"
    
    # Core setup steps (order matters)
    execute_step "Directory setup" setup_directories
    execute_step "Git configuration" setup_git
    execute_step "Network setup" setup_network
    execute_step "Audio setup (PipeWire)" setup_pipewire
    execute_step "Zsh setup" setup_zsh
    execute_step "Zsh plugins" setup_zsh_plugins
    execute_step "Python environment" setup_python_environment
    execute_step "Font installation" install_fonts
    execute_step "Display manager (ly)" setup_ly
    execute_step "USB configuration" disable_usb_autosuspend
    execute_step "Performance tweaks" tweak_performance
    execute_step "Security setup" setup_security
    execute_step "Maintenance setup" setup_maintenance
    execute_step "Neovim setup" setup_ui_enhancements
    
    # Optional: Clone dotfiles
    if [ -n "$DOTFILES_URL" ]; then
        execute_step "Dotfiles" clone_dotfiles
    fi
    
    # Optional: GRUB setup
    execute_step "GRUB configuration" setup_grub || true
    
    # Optional: Boot configuration (NVIDIA, initramfs)
    execute_step "Boot configuration" setup_boot || true
}

# Setup Flutter environment (if flutter package installed)
setup_flutter_if_available() {
    if command -v flutter &>/dev/null; then
        section "Flutter Setup" "$MAGENTA"
        execute_step "Flutter environment" setup_flutter_environment
        execute_step "Kolibri Shell" setup_kolibri_shell
    fi
}

# Cleanup
cleanup() {
    section "Cleanup" "$CYAN"
    log "INFO" "Running system cleanup"
    
    # Clean package caches
    yay -Yc --noconfirm 2>> "$LOG_FILE" || true
    sudo -n pacman -Sc --noconfirm 2>> "$LOG_FILE" || true
    
    # Remove orphaned packages
    local orphans=$(pacman -Qtdq 2>/dev/null)
    if [ -n "$orphans" ]; then
        sudo -n pacman -Rns $orphans --noconfirm 2>> "$LOG_FILE" || true
    fi
    
    echo -e "${GREEN}Cleanup completed!${NC}"
}

# Install command-line tools
install_cli_tools() {
    section "Installing Command-Line Tools" "$BLUE"
    
    # Create bin directory
    local bin_dir="$HOME/.local/bin"
    mkdir -p "$bin_dir"
    
    # Install sysunit
    local sysunit_src="$SCRIPT_DIR/bin/sysunit"
    local sysunit_dst="$bin_dir/sysunit"
    
    if [ -f "$sysunit_src" ]; then
        cp "$sysunit_src" "$sysunit_dst"
        chmod +x "$sysunit_dst"
        log "INFO" "Installed sysunit to $sysunit_dst"
        echo -e "${GREEN}✓ sysunit command installed${NC}"
    fi
    
    # Install apres-setup
    local apres_src="$SCRIPT_DIR/bin/apres-setup"
    local apres_dst="$bin_dir/apres-setup"
    
    if [ -f "$apres_src" ]; then
        cp "$apres_src" "$apres_dst"
        chmod +x "$apres_dst"
        log "INFO" "Installed apres-setup to $apres_dst"
        echo -e "${GREEN}✓ apres-setup command installed${NC}"
    fi
    
    # Ensure bin directory is in PATH
    if ! echo "$PATH" | grep -q "$bin_dir"; then
        echo -e "${YELLOW}Note: Add $bin_dir to your PATH${NC}"
        echo -e "${YELLOW}Add this line to your ~/.zshrc:${NC}"
        echo -e "${BLUE}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
    fi
}

# Print summary
print_summary() {
    echo ""
    section "Installation Complete" "$GREEN"
    
    if [ $ERRORS -eq 0 ]; then
        echo -e "${GREEN}╔═══════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                                       ║${NC}"
        echo -e "${GREEN}║   ✓ ALL STEPS COMPLETED SUCCESSFULLY  ║${NC}"
        echo -e "${GREEN}║                                       ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}"
    else
        echo -e "${YELLOW}╔═══════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║                                       ║${NC}"
        echo -e "${YELLOW}║   ⚠ COMPLETED WITH $ERRORS ERRORS        ║${NC}"
        echo -e "${YELLOW}║                                       ║${NC}"
        echo -e "${YELLOW}╚═══════════════════════════════════════╝${NC}"
        
        echo -e "\n${YELLOW}Failed steps:${NC}"
        for step in "${FAILED_STEPS[@]}"; do
            echo -e "  ${RED}✗${NC} $step"
        done
    fi
    
    echo -e "\n${BLUE}Next Steps:${NC}"
    echo -e "  1. ${GREEN}Log out and log back in${NC} to apply all changes"
    echo -e "  2. Run ${YELLOW}sysunit${NC} to verify system configuration"
    echo -e "  3. Run ${YELLOW}apres-setup start${NC} to install non-essential packages"
    echo -e "  4. Check the log file: ${BLUE}$LOG_FILE${NC}"
    
    if [ $ERRORS -gt 0 ]; then
        echo -e "\n${YELLOW}Some steps failed. Review the log for details.${NC}"
    fi
}

# Main function
main() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║                                                   ║"
    echo "║         ARCH LINUX ESSENTIAL SETUP                ║"
    echo "║                                                   ║"
    echo "║  This will install essential packages and         ║"
    echo "║  configure your system for immediate use.         ║"
    echo "║                                                   ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
    
    # Run installation steps
    preflight_checks
    system_update
    execute_step "YAY installation" install_yay
    execute_step "Flatpak setup" setup_flatpak
    install_essential_packages
    configure_system
    setup_flutter_if_available
    install_cli_tools
    cleanup
    print_summary
}

# Execute main function
main "$@"
