# Migration Guide

## Migrating from Old arch-setup.sh to New Structure

The setup has been refactored for better maintainability, error recovery, and flexibility. Here's what changed and how to migrate.

## What Changed?

### New Structure
```
Old:                          New:
arch-setup.sh          →      install-essential.sh (essential only)
                       +      apres-setup (non-essential packages)
                       +      sysunit (system tests)
                       
modules/packages.sh    →      config/packages-essential.sh
                       +      config/packages-nonessential.sh
                       +      lib/package-manager.sh
```

### Key Improvements

1. **Two-Phase Installation**
   - Phase 1: Essential packages (fast, stable)
   - Phase 2: Non-essential packages (can be paused/resumed)

2. **Better Error Handling**
   - Continues on errors
   - Tracks all failures
   - Can resume after interruption

3. **System Testing**
   - `sysunit` command validates your setup
   - Runs automatically after installation

4. **Progress Tracking**
   - Non-essential packages track progress
   - Can stop and resume anytime
   - Survives system reboots

5. **Package Separation**
   - Essential: Required for basic functionality
   - Non-essential: Optional tools and applications

6. **More Efficient Packages**
   - Uses -bin versions where available
   - Faster installation
   - Less compilation time

## Migration Steps

### Option 1: Fresh Installation (Recommended)

If starting fresh or can reinstall:

```bash
# 1. Backup your vars.sh configuration
cp vars.sh vars.sh.backup

# 2. Pull the latest changes
git pull origin main

# 3. Restore your configuration
cp vars.sh.backup vars.sh

# 4. Run new installation
chmod +x install-essential.sh
./install-essential.sh

# 5. After reboot, install non-essentials
apres-setup start
```

### Option 2: Keep Existing Setup

If you've already run arch-setup.sh and want to keep it:

```bash
# 1. Pull the latest changes
git pull origin main

# 2. Your existing installation continues to work

# 3. Optionally run system tests
chmod +x bin/sysunit
./bin/sysunit

# 4. Optionally install additional packages
chmod +x bin/apres-setup
./bin/apres-setup start
```

### Option 3: Hybrid Approach

Start using the new system while keeping existing installation:

```bash
# 1. Pull latest changes
git pull origin main

# 2. Test the system
chmod +x bin/sysunit
./bin/sysunit

# 3. Install additional non-essential packages
chmod +x bin/apres-setup
./bin/apres-setup start
```

## Comparing Old vs New

### Old Workflow
```bash
./arch-setup.sh
# Everything installs at once
# Errors stop or skip packages
# No progress tracking
# No system validation
```

### New Workflow
```bash
# Phase 1: Essential installation (required)
./install-essential.sh
# Log out/in

# Phase 2: Validate system
sysunit

# Phase 3: Non-essential packages (optional)
apres-setup start

# Can stop and resume anytime
apres-setup stop
apres-setup status
apres-setup start
```

## Package Redistribution

Packages have been reorganized into essential and non-essential categories:

### Moved to Essential
- All Hyprland packages
- Core system tools (git, neovim, etc.)
- Audio system (PipeWire)
- Display manager (ly)
- Shell (zsh)
- Network tools

### Moved to Non-Essential
- Development tools (VSCode, Docker, Android SDK)
- Browsers (Chrome, Zen)
- Gaming (Steam, Lutris, RetroArch)
- Productivity (LibreOffice, Obsidian)
- Communication (Discord, Vesktop)

## New Features

### System Unit Testing
```bash
# Run all tests
sysunit

# Tests validate:
# - Kernel functionality
# - Network connectivity
# - Audio system
# - Display configuration
# - Shell setup
# - Git configuration
# - Package managers
# - And more...
```

### Background Installation
```bash
# Start installation in background
apres-setup start &

# Check progress anytime
apres-setup status

# View detailed log
apres-setup log

# Stop if needed
apres-setup stop
```

### USB Configuration
Automatically disables USB autosuspend for better device reliability.

### Flutter/Kolibri Shell
Automatically detects Flutter and builds Kolibri Shell taskbar.

## Configuration Changes

### vars.sh
No changes needed! Your existing `vars.sh` works with the new system.

```bash
# All these still work:
GIT_NAME="Your Name"
GIT_EMAIL="your@email.com"
DOTFILES_URL="https://github.com/..."
KERNEL_TYPE="linux"
LOG_LEVEL="INFO"
```

## Troubleshooting Migration

### I ran arch-setup.sh, can I use the new system?

Yes! The new tools are additive:
- `sysunit` works on any system
- `apres-setup` only installs packages that aren't already installed

### My packages are in both lists now

That's fine! Package managers (`pacman`, `yay`) skip already-installed packages automatically.

### I want to use the old script

The old `arch-setup.sh` still works but shows a warning. You can continue using it, but the new method is recommended.

### How do I customize package lists?

Edit these files:
- `config/packages-essential.sh` - Required packages
- `config/packages-nonessential.sh` - Optional packages

### Can I add my own modules?

Yes! See the "Customization" section in README.md.

## Benefits of Migration

1. **Faster initial setup**: Only installs essential packages first
2. **More reliable**: Better error handling and recovery
3. **Testable**: Built-in system validation
4. **Flexible**: Install non-essentials at your own pace
5. **Resumable**: Stop and continue anytime
6. **Efficient**: Uses -bin packages where possible
7. **Maintainable**: Cleaner code structure

## Questions?

Check the main README.md or inspect the code:
- `install-essential.sh` - Main script
- `bin/apres-setup` - Non-essential installer
- `bin/sysunit` - System tester

## Rollback

If you want to go back to the old system:

```bash
# Checkout previous version
git log --oneline  # Find the commit before refactor
git checkout <commit-hash>
```

However, the new system is backward compatible, so this shouldn't be necessary.
