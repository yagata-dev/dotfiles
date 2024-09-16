#!/bin/sh

set -eu

install_chezmoi() {
    bin_dir="${HOME}/.local/bin"
    chezmoi="${bin_dir}/chezmoi"
    echo "Installing chezmoi to '${chezmoi}'" >&2
    if command -v curl >/dev/null; then
        chezmoi_install_script="$(curl -fsSL get.chezmoi.io)"
    elif command -v wget >/dev/null; then
        chezmoi_install_script="$(wget -qO- get.chezmoi.io)"
    else
        echo "To install chezmoi, you must have curl or wget installed." >&2
        exit 1
    fi
    sh -c "${chezmoi_install_script}" -- -b "${bin_dir}"
}

if ! chezmoi="$(command -v chezmoi)"; then
    install_chezmoi
fi

install_mac_packages() {
    echo "Detected macOS. Installing Homebrew and packages..."
    if ! command -v brew &>/dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew bundle --file=.Brewfile
}

install_linux_packages() {
    echo "Detected Linux. Installing packages with apt-get..."
    sudo apt-get update && \
    sudo apt-get install -y gpg bat && \
    sudo ln -s /usr/bin/batcat /usr/bin/bat
    # Find and execute all .sh scripts
    echo "Searching for .sh scripts..."
    find /dot_config/devcontainer -type f -name "*.sh" | while read -r script; do
        echo "Found script: $script"

        # Check if the file is readable and executable
        if [ -f "$script" ]; then
            sudo chmod +x "$script"
            echo "Executing $script..."
            sudo bash "$script"
        else
            echo "Script $script not found or not a file."
        fi
    done
}

if [ "$(uname)" = "Darwin" ]; then
    install_mac_packages
else
    install_linux_packages
fi

script_dir="$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P)"
set -- init --apply --source="${script_dir}"

echo "Running 'chezmoi $*'" >&2
exec "$chezmoi" "$@"