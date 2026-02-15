#!/bin/bash
# Bootstrap script for stellar-wallets skill
# Installs stellar-cli if not already present

set -e

check_stellar() {
    if command -v stellar &>/dev/null; then
        echo "stellar-cli is already installed: $(stellar version)" >&2
        return 0
    fi
    return 1
}

install_stellar() {
    echo "Installing stellar-cli..." >&2
    # Fallback to reliable .deb for Linux/Debian/Ubuntu
    if [ -f /etc/debian_version ]; then
        DEB_URL="https://github.com/stellar/stellar-cli/releases/download/v25.1.0/stellar-cli_25.1.0_amd64.deb"
        echo "Downloading $DEB_URL..."
        curl -L "$DEB_URL" -o /tmp/stellar.deb
        sudo dpkg -i /tmp/stellar.deb
        rm /tmp/stellar.deb
    else
        # Generic install for others
        curl -fsSL https://github.com/stellar/stellar-cli/raw/main/install.sh | sh
    fi
}

if ! check_stellar; then
    install_stellar
fi

if ! check_stellar; then
    echo "Error: stellar-cli installation failed" >&2
    exit 1
fi

echo "stellar-wallets skill is ready" >&2
