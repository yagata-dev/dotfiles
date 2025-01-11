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

install_tools() {
    echo "Installing additional tools..."

    # Install eza
    if ! command -v eza >/dev/null 2>&1; then
        echo "Installing eza..."
        if command -v brew >/dev/null 2>&1; then
            brew install eza
        elif command -v apt >/dev/null 2>&1; then
            sudo apt update && sudo apt install -y eza
        else
            echo "Could not install eza. Please install it manually."
        fi
    fi

    # Install fzf
    if ! command -v fzf >/dev/null 2>&1; then
        echo "Installing fzf..."
        if command -v brew >/dev/null 2>&1; then
            brew install fzf
            $(brew --prefix)/opt/fzf/install --key-bindings --completion --no-bash --no-fish
        elif command -v apt >/dev/null 2>&1; then
            sudo apt update && sudo apt install -y fzf
        else
            git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
            ~/.fzf/install --key-bindings --completion --no-bash --no-fish
        fi
    fi

    # Install zoxide
    if ! command -v zoxide >/dev/null 2>&1; then
        echo "Installing zoxide..."
        if command -v brew >/dev/null 2>&1; then
            brew install zoxide
        elif command -v apt >/dev/null 2>&1; then
            sudo apt update && sudo apt install -y zoxide
        else
            curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
        fi
    fi
}

if [ "$(uname)" = "Darwin" ]; then
    install_mac_packages
fi

install_tools

script_dir="$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P)"
set -- init --apply --source="${script_dir}"

echo "Running 'chezmoi $*'" >&2
exec "$chezmoi" "$@"