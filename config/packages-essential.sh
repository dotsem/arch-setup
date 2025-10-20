#!/usr/bin/env bash
# Essential packages needed for a functional system
# These packages are installed first and are critical for basic operation

# Core system packages
ESSENTIAL_PACMAN_PACKAGES=(
    # Kernel and base
    base-devel
    linux-firmware
    
    # Display server and window managers
    wayland
    xorg-server
    xorg-xinit
    xorg-xauth
    hyprland
    xdg-desktop-portal-hyprland
    
    # Display manager
    ly
    
    # Terminal and shell
    alacritty
    zsh
    zsh-syntax-highlighting
    zsh-autosuggestions
    
    # Audio
    pipewire
    pipewire-pulse
    pipewire-jack
    wireplumber
    pavucontrol
    
    # Network
    networkmanager
    networkmanager-openvpn
    openssh
    
    # File management
    lf
    udiskie
    
    # Essential utilities
    nano
    neovim
    git
    curl
    wget
    which
    unzip
    7zip
    jq
    xxd
    htop
    
    # Brightness and power
    brightnessctl
    tlp
    
    # Notifications
    dunst
    
    # File systems
    exfat-utils
    ntfs-3g
    btrfs-progs
    
    # Qt/GTK
    qt5
    qt6
    gtk-layer-shell
    
    # Hyprland ecosystem
    hyprpicker
    hypridle
    hyprlock
    hyprpaper
    hyprshot
    hyprutils
    hyprpolkitagent
    
    # Application launcher
    wofi
    
    # Flatpak
    flatpak
)

ESSENTIAL_AUR_PACKAGES=(
    # Shell
    oh-my-zsh-git
    
    # Wayland tools
    rofi-wayland
    
    # Hyprland extras
    hyprshell
    hyprsunset
)

ESSENTIAL_FLATPAK_PACKAGES=(
    # Add essential flatpaks here if needed
)
