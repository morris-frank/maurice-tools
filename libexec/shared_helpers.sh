#!/usr/bin/env bash
# shared_helpers.sh - Common functions for maurice-tools
# shellcheck shell=bash

# Colors for terminal output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
error() {
    echo -e "${RED}ERROR:${NC} $*" >&2
}

warn() {
    echo -e "${YELLOW}WARNING:${NC} $*" >&2
}

info() {
    echo -e "${BLUE}INFO:${NC} $*"
}

success() {
    echo -e "${GREEN}SUCCESS:${NC} $*"
}

# Check if running on macOS
check_macos() {
    if [[ "$(uname -s)" != "Darwin" ]]; then
        error "maurice-tools is designed for macOS only"
        exit 1
    fi
}

# Get macOS username for Keychain
get_macos_username() {
    id -un
}

# Configuration path helpers
get_config_dir() {
    echo "${HOME}/.config/maurice-tools"
}

get_config_file() {
    echo "$(get_config_dir)/config.toml"
}

# Ensure config directory exists
ensure_config_dir() {
    local config_dir
    config_dir=$(get_config_dir)
    if [[ ! -d "$config_dir" ]]; then
        mkdir -p "$config_dir"
    fi
}

# Check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Check if Homebrew is installed
check_homebrew() {
    if command_exists brew; then
        return 0
    else
        return 1
    fi
}

# Get Homebrew prefix
get_brew_prefix() {
    if check_homebrew; then
        brew --prefix
    else
        echo ""
    fi
}

# Check if a Homebrew formula is installed
brew_formula_installed() {
    local formula="$1"
    if ! check_homebrew; then
        return 1
    fi
    brew list "$formula" &>/dev/null
}

# Check if Python package is installed
python_package_installed() {
    local package="$1"
    python3 -c "import $package" 2>/dev/null
}

# Get services directory for Quick Actions
get_services_dir() {
    echo "${HOME}/Library/Services"
}

# Check if Quick Action is installed
quick_action_installed() {
    local action_name="$1"
    local services_dir
    services_dir=$(get_services_dir)
    [[ -d "$services_dir/$action_name.workflow" ]]
}

# Read a config value from TOML (simple parser)
# Usage: read_config <section> <key> [default_value]
read_config() {
    local section="$1"
    local key="$2"
    local default_value="${3:-}"
    local config_file
    config_file=$(get_config_file)
    
    if [[ ! -f "$config_file" ]]; then
        echo "$default_value"
        return 0
    fi
    
    # Simple TOML parsing: look for [section] then key = value
    local in_section=false
    local value=""
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        
        # Check for section header
        if [[ "$line" =~ ^\[([^]]+)\]$ ]]; then
            local current_section="${BASH_REMATCH[1]}"
            if [[ "$current_section" == "$section" ]]; then
                in_section=true
            else
                in_section=false
            fi
            continue
        fi
        
        # If in target section, look for key
        if $in_section && [[ "$line" =~ ^[[:space:]]*${key}[[:space:]]*=[[:space:]]*(.+)$ ]]; then
            value="${BASH_REMATCH[1]}"
            # Remove quotes if present
            value="${value#\"}"
            value="${value%\"}"
            value="${value#\'}"
            value="${value%\'}"
            echo "$value"
            return 0
        fi
    done < "$config_file"
    
    echo "$default_value"
}

# Expand tilde in paths
expand_path() {
    local path="$1"
    if [[ "$path" == ~* ]]; then
        echo "${path/\~/$HOME}"
    else
        echo "$path"
    fi
}

# Check if a secret exists in Keychain
secret_exists() {
    local service="$1"
    local account
    account=$(get_macos_username)
    
    security find-generic-password -s "$service" -a "$account" &>/dev/null
}

# Get version from git or file
get_version() {
    if [[ -d "${MAURICE_ROOT:-}/.git" ]]; then
        git -C "${MAURICE_ROOT}" describe --tags --always 2>/dev/null || echo "dev"
    else
        echo "0.1.0"
    fi
}
