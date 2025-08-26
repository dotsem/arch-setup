#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../helpers/ui.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../helpers/logging.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../vars.sh"

setup_pipewire() {
    # Check if PipeWire is installed
    check_pipewire_installed() {
        if ! pacman -Qi pipewire > /dev/null 2>&1; then
            log "ERROR" "PipeWire is not installed"
            echo -e "${RED}Error: PipeWire is not installed. Please install it first with:"
            echo -e "sudo pacman -S pipewire pipewire-pulse pipewire-jack wireplumber${NC}"
            return 1
        fi
        return 0
    }

    # Setup PipeWire services with retries
    setup_pipewire_services() {
        local services=("wireplumber" "pipewire" "pipewire-pulse")
        local failed=0
        
        for service in "${services[@]}"; do
            log "INFO" "Enabling and starting $service"
            if systemctl --user enable --now "$service" >> "$LOG_FILE" 2>&1; then
                log "INFO" "Successfully enabled $service"
                echo -e "${GREEN}Enabled and started $service${NC}"
                sleep 1  # Allow service to initialize
            else
                log "ERROR" "Failed to enable $service"
                echo -e "${RED}Failed to enable $service${NC}"
                failed=$((failed + 1))
            fi
        done
        
        # Verify services are running
        log "INFO" "Verifying services are running"
        for service in "${services[@]}"; do
            if systemctl --user is-active --quiet "$service"; then
                log "INFO" "$service is running"
            else
                log "ERROR" "$service is not running"
                echo -e "${RED}Warning: $service is not running${NC}"
                failed=$((failed + 1))
            fi
        done
        
        return $failed
    }

    # Audio priority setup
    setup_audio_priority() {
        log "INFO" "Configuring audio priority settings"
        
        local conf_dir="/etc/security/limits.d"
        local conf_file="$conf_dir/audio_priority.conf"
        local content="@audio - nice -10"
        
        sudo -n mkdir -p "$conf_dir" 2>> "$LOG_FILE" || {
            log "ERROR" "Failed to create $conf_dir"
            echo -e "${RED}Failed to create configuration directory!${NC}"
            return 1
        }
        
        if [ -f "$conf_file" ] && grep -qxF "$content" "$conf_file"; then
            log "INFO" "Audio priority already configured"
            echo -e "${GREEN}Audio priority already set!${NC}"
            return 0
        fi
        
        if echo "$content" | sudo -n tee "$conf_file" > /dev/null; then
            log "INFO" "Audio priority configuration saved"
            echo -e "${GREEN}Audio priority set successfully!${NC}"
            return 0
        else
            log "ERROR" "Failed to configure audio priority"
            echo -e "${RED}Failed to set audio priority!${NC}"
            return 1
        fi
    }

    # Check if user is in audio group
    check_audio_group() {
        log "INFO" "Checking if user is in audio group"
        
        if groups | grep -q '\baudio\b'; then
            log "INFO" "User is in audio group"
            echo -e "${GREEN}User is in audio group${NC}"
            return 0
        else
            log "WARNING" "User is NOT in audio group - adding now"
            echo -e "${YELLOW}User is not in audio group - attempting to add...${NC}"
            
            if sudo -n usermod -aG audio "$USER" >> "$LOG_FILE" 2>&1; then
                log "INFO" "Successfully added user to audio group"
                echo -e "${GREEN}User added to audio group successfully!${NC}"
                return 0
            else
                log "ERROR" "Failed to add user to audio group"
                echo -e "${RED}Failed to add user to audio group!${NC}"
                return 1
            fi
        fi
    }

    # Verify PipeWire is working
    verify_pipewire() {
        log "INFO" "Running verification checks"
        
        local errors=0
        
        if pactl info | grep -q "PipeWire"; then
            log "INFO" "PipeWire is running as the audio server"
            echo -e "${GREEN}PipeWire is running as the audio server${NC}"
        else
            log "ERROR" "PipeWire is not running as the audio server"
            echo -e "${RED}Error: PipeWire is not running as the audio server${NC}"
            errors=$((errors + 1))
        fi
        
        local processes=("pipewire" "pipewire-pulse" "wireplumber")
        for proc in "${processes[@]}"; do
            if pgrep -x "$proc" > /dev/null; then
                log "INFO" "Process $proc is running"
            else
                log "ERROR" "Process $proc is not running"
                echo -e "${RED}Error: Process $proc is not running${NC}"
                errors=$((errors + 1))
            fi
        done
        
        return $errors
    }

#     setup_persistent_naming() {
#     section "PERSISTENT AUDIO NAMING" "$CYAN"
    
#     local config_dir="$HOME/.config/wireplumber/main.lua.d"
    
#     # Create default mapping file if missing
#     if [ ! -f "$AUDIO_NAMING_FILE" ]; then
#         cat > "$AUDIO_NAMING_FILE" << 'EOF'
# # Add your custom device names below
# # Format: <ALSA_ID>=<Friendly Name>
# # Get IDs from: pw-cli list-objects | grep -A1 "device.api.alsa.card"
# #
# # Examples:
# # pci-0000_26_00.1=GPU HDMI Audio
# # usb-Logitech_PRO_00=Headset
# EOF
#         echo -e "${YELLOW}Created name template at $AUDIO_NAMING_FILE${NC}"
#         echo -e "Edit this file with your preferred names and rerun the script"
#         return 1
#     fi

#     # Generate dynamic Lua config
#     mkdir -p "$config_dir"
#     cat > "$config_dir/93-persistent-names.lua" << EOF
# local name_map = {
# $(
#     # Convert config file to Lua table
#     grep -v '^#' "$AUDIO_NAMING_FILE" | grep '=' | while read -r line; do
#         alsa_id="${line%%=*}"
#         name="${line#*=}"
#         echo "    [\"$alsa_id\"] = \"$name\","
#     done
# )
# }

# alsa_monitor.rules = {
#     {
#         matches = {
#             { "device.api.alsa.card", "matches", ".*" },
#         },
#         apply_properties = {
#             ["device.description"] = function(context, props)
#                 return name_map[props["device.api.alsa.card"]] or 
#                        props["device.description"]
#             end,
#             ["node.description"] = function(context, props)
#                 local base_name = name_map[props["device.api.alsa.card"]] or
#                                  props["device.description"]
#                 local port = props["port.name"] or ""
                
#                 -- Add port info for GPU outputs
#                 if props["device.api.alsa.card-name"]:match("TU106") then
#                     local num = props["node.name"]:match("pro%-output%-(%d+)") or
#                                props["device.api.alsa.physical-port"]:match("(%d+)$") or ""
#                     if num ~= "" then
#                         return base_name .. " Port " .. num
#                     end
#                 end
#                 return base_name
#             end
#         }
#     }
# }
# EOF

#     # Apply changes
#     systemctl --user restart wireplumber
#     sleep 2

#     # Verify
#     echo -e "${GREEN}Current device names:${NC}"
#     pw-cli list-objects | grep -A1 -E "device.api.alsa.card|node.description" | \
#     awk '/device.api.alsa.card/ {printf "%-40s", "Device: " $2} /node.description/ {print "-> " $0}'
# }

    # Main setup function
    local overall_success=0
    
    check_pipewire_installed || overall_success=1
    setup_pipewire_services || overall_success=1
    setup_audio_priority || overall_success=1
    check_audio_group || overall_success=1
    verify_pipewire || overall_success=1
    
    if [ $overall_success -eq 0 ]; then
        log "INFO" "Setup completed successfully"
        echo -e "${GREEN}=== PipeWire and system appearance configured! ==="
        echo -e "You may need to logout for all changes to take effect${NC}"
    else
        log "ERROR" "Setup completed with errors"
        echo -e "${YELLOW}=== Setup completed with some warnings ==="
        echo -e "Check $LOG_FILE for details${NC}"
    fi
    
    return $overall_success
}