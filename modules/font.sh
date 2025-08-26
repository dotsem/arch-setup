# #!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../helpers/ui.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../helpers/logging.sh"

install_fonts() {
    section_header "Installing System Fonts"
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"

    # 1. Material Symbols Rounded (Quickshell compatible)
    TARGET="$FONT_DIR/MaterialSymbolsRounded.ttf"
    FONT_URL="https://github.com/google/material-design-icons/raw/refs/heads/master/variablefont/MaterialSymbolsRounded%5BFILL,GRAD,opsz,wght%5D.ttf"

    print_status info "Downloading TTF font..."
    if ! curl -fSLo "$TARGET" "$FONT_URL"; then
        print_status error "Download failed"
        log "ERROR" "failed to download Material Symbols Rounded font" 
    else
        # Verify it's a TrueType font
        if ! file "$TARGET" | grep -q "TrueType"; then
            print_status error "Invalid font file (not TTF)"
            rm -f "$TARGET"
            log "ERROR" "downloaded Material Symbols Rounded font is not a TrueType font"
        else
            log "INFO" "successfully donwloaded Material Symbols Rounded font"
        fi  
    fi

    # 2. JetBrains Mono (for coding)
    print_status info "Installing JetBrains Mono..."
    JETBRAINS_URL="https://download.jetbrains.com/fonts/JetBrainsMono-2.304.zip"
    if ! (curl -fsSLo /tmp/jetbrains.zip "$JETBRAINS_URL" && \
          unzip -qjo /tmp/jetbrains.zip "fonts/ttf/*.ttf" -d "$FONT_DIR/JetBrainsMono" && \
          rm /tmp/jetbrains.zip); then
        print_status error "JetBrains Mono installation failed"
        log "ERROR" "failed to download JetBrains Mono font"
    else 
        log "INFO" "successfully downloaded JetBrains Mono font"
    fi

    # 3. Nerd Font for Starship (with icons)
    print_status info "Installing FiraCode Nerd Font..."
    NERD_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/FiraCode.zip"
    if ! (curl -fsSLo /tmp/fira-code.zip "$NERD_FONT_URL" && \
          unzip -qjo /tmp/fira-code.zip "*.ttf" -d "$FONT_DIR/FiraCodeNerd" && \
          rm /tmp/fira-code.zip); then
        print_status error "Nerd Font installation failed"
        log "ERROR" "failed to download FiraCode Nerd Font"
    else
        log "INFO" "successfully downloaded FiraCode Nerd Font"
    fi

    # Font cache update
    if fc-cache -fv; then
        print_status success "Font cache updated"
        log "INFO" "updated font cache"
    else
        print_status error "Font cache update failed"
        log "ERROR" "failed to update font cache"
        return 1
    fi
}

