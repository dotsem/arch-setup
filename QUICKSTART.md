# Quick Start Guide

## For New Arch Linux Installations

### Step 1: Clone Repository
```bash
git clone https://github.com/dotsem/arch-setup.git
cd arch-setup
```

### Step 2: Configure
```bash
# Edit configuration file
nano vars.sh

# Set at minimum:
# - GIT_NAME="Your Name"
# - GIT_EMAIL="your.email@example.com"
# - DOTFILES_URL="https://github.com/yourusername/.config.git" (optional)
```

### Step 3: Check Requirements (Optional but Recommended)
```bash
./check-requirements.sh
```

### Step 4: Install

**Option A: Interactive Menu (Easiest)**
```bash
./setup-menu.sh
# Then select option 1 (Fresh Installation)
```

**Option B: Direct Installation**
```bash
./install-essential.sh
```

### Step 5: Reboot
```bash
# Log out and log back in, or reboot
reboot
```

### Step 6: Verify Installation
```bash
# Run system tests
sysunit
```

### Step 7: Install Optional Packages (Optional)
```bash
# Install non-essential packages in the background
apres-setup start

# Check progress anytime
apres-setup status
```

## What Gets Installed

### Essential Packages (Phase 1)
- **Wayland/Hyprland** - Window manager and compositor
- **Audio** - PipeWire, WirePlumber
- **Terminal** - Alacritty + Zsh
- **Network** - NetworkManager
- **Display Manager** - ly
- **Basic Tools** - Git, Neovim, file managers
- **Fonts** - JetBrains Mono, FiraCode Nerd Font, Material Symbols

### Non-Essential Packages (Phase 2 - Optional)
- **Development** - VSCode, Docker, Android SDK, Flutter
- **Browsers** - Chrome, Zen Browser
- **Gaming** - Steam, Lutris, RetroArch
- **Productivity** - LibreOffice, Obsidian
- **Communication** - Discord, Vesktop

## Time Estimates

- **Essential Installation**: 15-30 minutes (depending on internet speed)
- **Non-Essential Installation**: 30-60 minutes (background, resumable)
- **System Tests**: 1-2 minutes

## Troubleshooting

### Installation Fails
```bash
# Check the log
less ~/arch_setup.log

# Run requirements check
./check-requirements.sh

# Try again (it will skip already-installed packages)
./install-essential.sh
```

### System Test Fails
```bash
# Run tests to see what's wrong
sysunit

# Check specific component logs
journalctl -xe
```

### Can't Find Commands (sysunit, apres-setup)
```bash
# Add ~/.local/bin to PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## Common Commands

```bash
# Run interactive menu
./setup-menu.sh

# Check system requirements
./check-requirements.sh

# Install essential packages
./install-essential.sh

# Run system tests
sysunit

# Start non-essential installation
apres-setup start

# Check installation progress
apres-setup status

# Stop non-essential installation
apres-setup stop

# View installation log
less ~/arch_setup.log

# View apres-setup log
apres-setup log
```

## After Installation

1. **Log out and back in** for all changes to take effect
2. **Run `sysunit`** to verify everything works
3. **Configure your dotfiles** (if you provided a DOTFILES_URL)
4. **Run `apres-setup start`** if you want optional packages
5. **Enjoy your new Arch setup!**

## Need Help?

- Read **README.md** for detailed documentation
- Check **MIGRATION.md** if upgrading from old script
- Review **TODO-STATUS.md** for feature list
- Read **SUMMARY.md** for architecture overview

## Tips

- Run `check-requirements.sh` first to catch issues early
- Use the interactive menu (`setup-menu.sh`) for easier navigation
- The installation logs everything to `~/arch_setup.log`
- You can stop and resume non-essential installation anytime
- System tests help identify configuration issues quickly

## Configuration Options

Edit `vars.sh` to customize:

```bash
GIT_NAME="Your Name"              # Required
GIT_EMAIL="your.email@example.com" # Required
DOTFILES_URL="https://..."         # Optional
KERNEL_TYPE="linux"                # or linux-lts, linux-zen
LOG_LEVEL="INFO"                   # DEBUG, INFO, WARN, ERROR
USB_MOUNT_PATH="/mnt/usb"         # Optional
```

## What's Different from Standard Arch?

After installation, your system will have:

- ✅ Hyprland (Wayland compositor)
- ✅ ly display manager
- ✅ Zsh with Oh My Zsh
- ✅ PipeWire audio
- ✅ Modern tools and utilities
- ✅ Optimized performance settings
- ✅ Security hardening (UFW firewall)
- ✅ Automatic maintenance tasks

Enjoy your new Arch Linux setup! 🎉
