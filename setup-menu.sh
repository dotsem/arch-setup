#!/bin/bash
# Installation wrapper script - Provides easy access to both installation methods

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

show_menu() {
    clear
    echo -e "${BLUE}╔═══════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                                                   ║${NC}"
    echo -e "${BLUE}║           ARCH LINUX SETUP INSTALLER              ║${NC}"
    echo -e "${BLUE}║                                                   ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════╝${NC}\n"
    
    echo -e "${CYAN}What would you like to do?${NC}\n"
    echo -e "  ${GREEN}1)${NC} Fresh Installation (Recommended)"
    echo -e "     → Install essential packages only"
    echo -e "     → Fast and reliable"
    echo -e "     → Can add more later with apres-setup\n"
    
    echo -e "  ${GREEN}2)${NC} Continue/Resume Non-Essential Installation"
    echo -e "     → Install optional packages"
    echo -e "     → Can pause and resume anytime\n"
    
    echo -e "  ${GREEN}3)${NC} System Test"
    echo -e "     → Validate your system configuration"
    echo -e "     → Check if everything works\n"
    
    echo -e "  ${GREEN}4)${NC} Check Installation Status"
    echo -e "     → View installation progress\n"
    
    echo -e "  ${GREEN}5)${NC} Legacy Installation"
    echo -e "     → Install everything at once (old method)\n"
    
    echo -e "  ${GREEN}6)${NC} View Documentation"
    echo -e "     → README, Migration Guide, etc.\n"
    
    echo -e "  ${GREEN}q)${NC} Quit\n"
    
    echo -ne "${YELLOW}Enter your choice:${NC} "
}

fresh_installation() {
    echo -e "\n${BLUE}Starting fresh installation...${NC}\n"
    
    if [ ! -f "$SCRIPT_DIR/install-essential.sh" ]; then
        echo -e "${RED}Error: install-essential.sh not found!${NC}"
        return 1
    fi
    
    bash "$SCRIPT_DIR/install-essential.sh"
}

resume_nonessential() {
    echo -e "\n${BLUE}Starting/resuming non-essential installation...${NC}\n"
    
    if [ ! -f "$SCRIPT_DIR/bin/apres-setup" ]; then
        echo -e "${RED}Error: apres-setup not found!${NC}"
        return 1
    fi
    
    bash "$SCRIPT_DIR/bin/apres-setup" start
}

system_test() {
    echo -e "\n${BLUE}Running system tests...${NC}\n"
    
    if [ ! -f "$SCRIPT_DIR/bin/sysunit" ]; then
        echo -e "${RED}Error: sysunit not found!${NC}"
        return 1
    fi
    
    bash "$SCRIPT_DIR/bin/sysunit"
}

check_status() {
    echo -e "\n${BLUE}Checking installation status...${NC}\n"
    
    # Check if essential installation was run
    if [ -f "$HOME/arch_setup.log" ]; then
        echo -e "${GREEN}✓${NC} Essential installation log exists"
        
        local log_size=$(du -h "$HOME/arch_setup.log" | cut -f1)
        echo -e "  Log size: $log_size"
        
        local last_line=$(tail -n 1 "$HOME/arch_setup.log" 2>/dev/null)
        if echo "$last_line" | grep -q "Setup Complete"; then
            echo -e "${GREEN}✓${NC} Essential installation completed"
        else
            echo -e "${YELLOW}⚠${NC} Essential installation may be incomplete"
        fi
    else
        echo -e "${YELLOW}⚠${NC} No essential installation log found"
        echo -e "  Run option 1 for fresh installation"
    fi
    
    echo ""
    
    # Check apres-setup status
    if [ -f "$SCRIPT_DIR/bin/apres-setup" ]; then
        bash "$SCRIPT_DIR/bin/apres-setup" status
    else
        echo -e "${YELLOW}⚠${NC} apres-setup not found"
    fi
    
    echo ""
    
    # Check for sysunit
    if command -v sysunit &>/dev/null || [ -f "$SCRIPT_DIR/bin/sysunit" ]; then
        echo -e "${GREEN}✓${NC} System test tool (sysunit) available"
    else
        echo -e "${YELLOW}⚠${NC} System test tool not found"
    fi
}

legacy_installation() {
    echo -e "\n${YELLOW}Starting legacy installation...${NC}\n"
    
    if [ ! -f "$SCRIPT_DIR/arch-setup.sh" ]; then
        echo -e "${RED}Error: arch-setup.sh not found!${NC}"
        return 1
    fi
    
    bash "$SCRIPT_DIR/arch-setup.sh"
}

view_docs() {
    clear
    echo -e "${BLUE}╔═══════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              DOCUMENTATION                        ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════╝${NC}\n"
    
    echo -e "${CYAN}Available documentation:${NC}\n"
    echo -e "  ${GREEN}1)${NC} README.md - Main documentation"
    echo -e "  ${GREEN}2)${NC} MIGRATION.md - Migration guide"
    echo -e "  ${GREEN}3)${NC} TODO-STATUS.md - Feature completion status"
    echo -e "  ${GREEN}4)${NC} Back to main menu\n"
    
    echo -ne "${YELLOW}Enter your choice:${NC} "
    read -r doc_choice
    
    case $doc_choice in
        1)
            if [ -f "$SCRIPT_DIR/README.md" ]; then
                less "$SCRIPT_DIR/README.md"
            else
                echo -e "${RED}README.md not found${NC}"
            fi
            ;;
        2)
            if [ -f "$SCRIPT_DIR/MIGRATION.md" ]; then
                less "$SCRIPT_DIR/MIGRATION.md"
            else
                echo -e "${RED}MIGRATION.md not found${NC}"
            fi
            ;;
        3)
            if [ -f "$SCRIPT_DIR/TODO-STATUS.md" ]; then
                less "$SCRIPT_DIR/TODO-STATUS.md"
            else
                echo -e "${RED}TODO-STATUS.md not found${NC}"
            fi
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            ;;
    esac
    
    echo -e "\n${YELLOW}Press Enter to continue...${NC}"
    read
}

# Main loop
main() {
    while true; do
        show_menu
        read -r choice
        
        case $choice in
            1)
                fresh_installation
                echo -e "\n${YELLOW}Press Enter to continue...${NC}"
                read
                ;;
            2)
                resume_nonessential
                echo -e "\n${YELLOW}Press Enter to continue...${NC}"
                read
                ;;
            3)
                system_test
                echo -e "\n${YELLOW}Press Enter to continue...${NC}"
                read
                ;;
            4)
                check_status
                echo -e "\n${YELLOW}Press Enter to continue...${NC}"
                read
                ;;
            5)
                legacy_installation
                echo -e "\n${YELLOW}Press Enter to continue...${NC}"
                read
                ;;
            6)
                view_docs
                ;;
            q|Q)
                echo -e "\n${GREEN}Goodbye!${NC}\n"
                exit 0
                ;;
            *)
                echo -e "\n${RED}Invalid choice. Press Enter to try again...${NC}"
                read
                ;;
        esac
    done
}

# Run main function
main
