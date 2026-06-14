#!/usr/bin/env bash
set -euo pipefail

# install.sh - Alternative curl-based installer for maurice-tools
# Usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/morris-frank/maurice-tools/main/install.sh)"

readonly REPO="morris-frank/maurice-tools"
readonly TAP="morris-frank/maurice-tools"
readonly FORMULA="maurice-tools"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

error() {
    echo -e "${RED}ERROR:${NC} $*" >&2
}

info() {
    echo -e "${BLUE}INFO:${NC} $*"
}

success() {
    echo -e "${GREEN}SUCCESS:${NC} $*"
}

warn() {
    echo -e "${YELLOW}WARNING:${NC} $*"
}

# Check if running on macOS
check_macos() {
    if [[ "$(uname -s)" != "Darwin" ]]; then
        error "maurice-tools is designed for macOS only"
        exit 1
    fi
}

# Check if Homebrew is installed
has_homebrew() {
    command -v brew &>/dev/null
}

# Main installation
main() {
    echo "Maurice Tools Installer"
    echo "======================"
    echo

    # Check macOS
    check_macos

    # Check for Homebrew
    if ! has_homebrew; then
        info "Homebrew is not installed. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for this session
        if [[ -d "/opt/homebrew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -d "/usr/local/Homebrew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi

    if ! has_homebrew; then
        error "Homebrew installation failed or not in PATH"
        exit 1
    fi

    success "Homebrew is installed"
    echo

    # Tap and install
    info "Adding tap: $TAP"
    brew tap "$TAP" || warn "Tap already exists or failed"
    echo

    info "Installing maurice-tools..."
    if brew install "$FORMULA"; then
        success "maurice-tools installed successfully"
    else
        error "Installation failed"
        exit 1
    fi
    echo

    # Run setup
    info "Running maurice setup..."
    if command -v maurice &>/dev/null; then
        maurice setup
    else
        warn "maurice command not in PATH after installation"
        info "Please restart your terminal and run: maurice setup"
    fi

    echo
    success "Installation complete!"
    echo
    echo "Quick start:"
    echo "  maurice doctor          - Check system health"
    echo "  maurice secret set openai - Configure OpenAI API key"
    echo "  maurice transcribe <file> - Transcribe audio"
    echo
}

main "$@"
