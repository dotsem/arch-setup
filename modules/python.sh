#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../helpers/ui.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../helpers/logging.sh"

setup_python_environment() {
    # Check if Python is installed
    check_python_installed() {
        if ! command -v python3 &> /dev/null; then
            log "ERROR" "Python3 is not installed"
            echo -e "${RED}Error: Python3 is not installed${NC}"
            return 1
        fi
        
        local python_version=$(python3 --version 2>&1 | awk '{print $2}')
        log "INFO" "Found Python version $python_version"
        echo -e "${GREEN}Python $python_version detected${NC}"
        return 0
    }

    # Install tkinter if missing
    install_tkinter() {
        if python3 -c "import tkinter" &> /dev/null; then
            log "INFO" "tkinter is already available"
            echo -e "${GREEN}tkinter is already installed${NC}"
            return 0
        fi

        log "INFO" "Installing tkinter"
        echo -e "${YELLOW}Installing tkinter...${NC}"
        
        local distro=""
        if [ -f /etc/os-release ]; then
            distro=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
        fi

        case "$distro" in
            "ubuntu"|"debian")
                sudo -n apt-get install -y python3-tk
                ;;
            "arch")
                sudo -n pacman -S --noconfirm tk
                ;;
            "fedora"|"centos"|"rhel")
                sudo -n dnf install -y python3-tkinter
                ;;
            *)
                log "WARN" "Unknown distribution - attempting pip install"
                python3 -m pip install tk --break-system-packages
                ;;
        esac

        if python3 -c "import tkinter" &> /dev/null; then
            log "INFO" "tkinter installed successfully"
            echo -e "${GREEN}tkinter installed!${NC}"
            return 0
        else
            log "ERROR" "Failed to install tkinter"
            echo -e "${RED}Failed to install tkinter!${NC}"
            return 1
        fi
    }

    # Test Python functionality
    test_python() {
        log "INFO" "Testing basic Python functionality"
        
        if ! python3 -c "print('Python test successful')"; then
            log "ERROR" "Basic Python test failed"
            echo -e "${RED}Basic Python test failed!${NC}"
            return 1
        fi

        log "INFO" "Testing pip functionality"
        if ! python3 -m pip --version; then
            log "ERROR" "Pip test failed"
            echo -e "${RED}Pip test failed!${NC}"
            return 1
        fi

        log "INFO" "Python tests passed"
        echo -e "${GREEN}Python basic tests passed!${NC}"
        return 0
    }

    # Test virtual environment creation
    test_venv() {
        local test_dir=$(mktemp -d)
        log "INFO" "Testing virtual environment creation in $test_dir"
        
        if python3 -m venv "$test_dir/test_venv"; then
            log "INFO" "Virtual environment created successfully"
            
            # Test activation
            if source "$test_dir/test_venv/bin/activate"; then
                log "INFO" "Virtual environment activated successfully"
                deactivate
                rm -rf "$test_dir"
                echo -e "${GREEN}Virtual environment test passed!${NC}"
                return 0
            else
                log "ERROR" "Failed to activate virtual environment"
                rm -rf "$test_dir"
                echo -e "${RED}Virtual environment activation failed!${NC}"
                return 1
            fi
        else
            log "ERROR" "Failed to create virtual environment"
            rm -rf "$test_dir"
            echo -e "${RED}Virtual environment creation failed!${NC}"
            return 1
        fi
    }

    # Main setup function
    local overall_success=0
    
    section "Python Environment Setup" "$YELLOW"
    
    check_python_installed || overall_success=1
    ensure_pip || overall_success=1
    install_tkinter || overall_success=1
    test_python || overall_success=1
    test_venv || overall_success=1
    
    if [ "$overall_success" -eq 0 ]; then
        log "INFO" "Python environment setup completed successfully"
        echo -e "\n${GREEN}Python environment is ready!${NC}"
    else
        log "ERROR" "Python environment setup encountered errors"
        echo -e "\n${YELLOW}Python setup completed with some warnings/errors${NC}"
    fi
    
    return $overall_success
}