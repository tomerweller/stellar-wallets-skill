#!/bin/bash
# Bootstrap script for stellar-wallets skill
# Installs stellar-cli if not already present

set -e

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${SKILL_DIR}/scripts"

check_stellar() {
    if command -v stellar &>/dev/null; then
        echo "stellar-cli is already installed: $(stellar version)" >&2
        return 0
    fi
    return 1
}

install_stellar() {
    echo "Installing stellar-cli..." >&2

    case "$(uname -s)" in
        Linux*|Darwin*)
            if command -v brew &>/dev/null; then
                echo "Installing via Homebrew..." >&2
                brew install stellar-cli
            elif command -v cargo &>/dev/null; then
                echo "Installing via Cargo..." >&2
                cargo install --locked stellar-cli
            elif command -v curl &>/dev/null; then
                echo "Installing via install script..." >&2
                curl -fsSL https://github.com/stellar/stellar-cli/raw/main/install.sh | sh
            else
                echo "Error: No supported package manager found (brew, cargo, or curl required)" >&2
                exit 1
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            if command -v cargo &>/dev/null; then
                echo "Installing via Cargo..." >&2
                cargo install --locked stellar-cli
            else
                echo "Error: Cargo is required to install stellar-cli on Windows" >&2
                exit 1
            fi
            ;;
        *)
            echo "Error: Unsupported operating system: $(uname -s)" >&2
            exit 1
            ;;
    esac
}

setup_scripts() {
    mkdir -p "${SCRIPTS_DIR}"
    chmod +x "${SCRIPTS_DIR}"/*.sh 2>/dev/null || true
}

main() {
    if ! check_stellar; then
        install_stellar
    fi

    if ! check_stellar; then
        echo "Error: stellar-cli installation failed" >&2
        exit 1
    fi

    setup_scripts

    echo "stellar-wallets skill is ready" >&2
}

main "$@"
