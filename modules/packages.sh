#!/bin/bash
# Main installation script

# Load helpers
source "$(dirname "${BASH_SOURCE[0]}")/../helpers/ui.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../helpers/logging.sh"

install_package() {
    local installer="$1"
    local package="$2"
    
    for attempt in {1..2}; do
        log "INFO" "Installation attempt $attempt for $package"
        
        case $installer in
            pacman)
                if sudo -n pacman -S --noconfirm --needed "$package"; then
                    log "INFO" "Successfully installed $package via pacman"
                    return 0
                else
                    log "WARN" "Attempt $attempt failed for $package (pacman)"
                fi
                ;;
            yay)
                if yay -S --noconfirm --needed "$package"; then
                    log "INFO" "Successfully installed $package via yay"
                    return 0
                else
                    log "WARN" "Attempt $attempt failed for $package (yay)"
                fi
                ;;
            flatpak)
                if flatpak install -y flathub "$package"; then
                    log "INFO" "Successfully installed $package via Flatpak"
                    return 0
                else
                    log "WARN" "Attempt $attempt failed for $package (Flatpak)"
                fi
                ;;
        esac
    done
    
    log "ERROR" "All installation attempts failed for $package"
    return 1
}

# Install yay AUR helper
install_yay() {
    section "Installing YAY AUR Helper"
    log "INFO" "Starting YAY installation"
    
    if ! command -v yay &>/dev/null; then
        log "DEBUG" "Installing dependencies"
        sudo -n pacman -S --needed --noconfirm git base-devel || {
            log "ERROR" "Failed to install dependencies"
            return 1
        }
        
        rm -rf /tmp/yay
        log "INFO" "Cloning YAY repository"
        git clone https://aur.archlinux.org/yay.git /tmp/yay || {
            log "ERROR" "Failed to clone YAY repo"
            return 1
        }
        
        cd /tmp/yay
        if [ "$(id -u)" -eq 0 ]; then
            log "ERROR" "makepkg should NOT be run as root. Aborting YAY build."
            cd - >/dev/null
            return 1
        fi
        
        log "INFO" "Building YAY package"
        makepkg -si --noconfirm || {
            log "ERROR" "YAY build failed"
            cd - >/dev/null
            return 1
        }
        cd - >/dev/null
        
        log "INFO" "YAY installed successfully"
        echo -e "${GREEN}Yay installed!${NC}"
    else
        log "INFO" "YAY already installed"
        echo -e "${GREEN}Yay already installed!${NC}"
    fi
}

# Ensure Flatpak and Flathub are set up
setup_flatpak() {
    section "Setting up Flatpak"
    log "INFO" "Installing Flatpak if missing"
    sudo -n pacman -S --needed --noconfirm flatpak || {
        log "ERROR" "Failed to install Flatpak"
        return 1
    }

    if ! flatpak remotes | grep -q flathub; then
        log "INFO" "Adding Flathub remote"
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    fi
}

# Example Flatpak package list
FLATPAK_PACKAGES=(
    org.gnome.Mahjongg com.github.wwmm.easyeffects
)

# Package lists
PACMAN_PACKAGES=(
    $KERNEL_TYPE-headers
    7zip alacritty brightnessctl blueman cava clang cmake cowsay curl dunst feh gcc
    helvum hwinfo hyprland i3-wm ly jq lf udiskie
    nano nodejs npm openttd pavucontrol polybar python python-pip rust htop
    pipewire pipewire-pulse pipewire-jack wireplumber
    which zsh unzip wine go flatpak php mysql docker xdg-desktop-portal-hyprland
    qt5 qt6 wayland xorg-xinit xorg-xauth xorg-server wofi os-prober github-cli
    zsh-syntax-highlighting zsh-autosuggestions xxd neovim gwenview ardour gtk-layer-shell
    hyprpicker hypridle hyprlock hyprpaper hyprshot hyprutils hyprpolkitagent
    libreoffice-still obsidian docker-compose qalculate-gtk easyeffects nwg-look
)

AUR_PACKAGES=(
    android-sdk google-chrome hyprshell hyprsunset quickshell-git rofi-wayland
    visual-studio-code-bin angular-cli zen-browser-bin flutter
    oh-my-zsh-git xampp tuxguitar vesktop-bin obs-studio steam neofetch lutris gamemode
    ntfs-3g exfat-utils btrfs-progs networkmanager-openvpn openssh xwaylandvideobridge
)

# Detect NVIDIA GPU and add drivers if needed
if lspci | grep -qi nvidia; then
    if ! [[ " ${PACMAN_PACKAGES[@]} " =~ " nvidia " ]]; then
        PACMAN_PACKAGES+=(nvidia nvidia-utils nvidia-settings)
    fi
fi

