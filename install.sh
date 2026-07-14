#!/usr/bin/env bash
# Single entry point for macOS, WSL and bare Linux (cloud GPU box) setup.
# Usage: ./install.sh
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { echo -e "\n=== $1 ===\n"; }

# --- Steps shared by every OS, always run as the real (non-root) user ---

setup_ssh_keys() {
    log "SSH keys"
    mkdir -p ~/.ssh

    if [ ! -f ~/.ssh/gh ]; then
        read -rp "Email for the SSH key comment (GitHub): " KEY_EMAIL
        ssh-keygen -t ed25519 -C "$KEY_EMAIL" -f ~/.ssh/gh -N ""
    else
        echo "~/.ssh/gh already exists, skipping key generation."
    fi

    cat > ~/.ssh/config << 'CONFIG'
Host github.com
    User git
    HostName github.com
    IdentityFile ~/.ssh/gh
    IdentitiesOnly yes
CONFIG

    if [ -f "$DOTFILES_DIR/ssh_config.local" ]; then
        echo "Appending personal host entries from ssh_config.local..."
        echo "" >> ~/.ssh/config
        cat "$DOTFILES_DIR/ssh_config.local" >> ~/.ssh/config
    else
        echo "No ssh_config.local found - copy ssh_config.local.example if you need extra hosts."
    fi

    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/config ~/.ssh/gh

    echo "--- Public key (add to GitHub: Settings -> SSH and GPG keys) ---"
    cat ~/.ssh/gh.pub
}

setup_shell_common() {
    log "Oh My Zsh, theme and aliases"

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    mkdir -p "$HOME/.oh-my-zsh/custom/themes"
    cp -f "$DOTFILES_DIR/my_them.zsh-theme" "$HOME/.oh-my-zsh/custom/themes/my_them.zsh-theme"

    touch "$HOME/.zshrc"
    if grep -q '^ZSH_THEME=' "$HOME/.zshrc"; then
        sed -i.bak 's/ZSH_THEME="[^"]*"/ZSH_THEME="my_them"/' "$HOME/.zshrc" && rm -f "$HOME/.zshrc.bak"
    else
        echo 'ZSH_THEME="my_them"' >> "$HOME/.zshrc"
    fi

    if ! grep -q "source $DOTFILES_DIR/aliases" "$HOME/.zshrc"; then
        echo "source $DOTFILES_DIR/aliases" >> "$HOME/.zshrc"
    fi
}

# --- Per-OS setup ---

setup_macos() {
    log "macOS setup"

    if ! command -v brew &>/dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
    fi
    eval "$(/opt/homebrew/bin/brew shellenv)"

    if [ -f "$DOTFILES_DIR/Brewfile" ]; then
        brew bundle --file="$DOTFILES_DIR/Brewfile"
    fi

    if command -v rustup-init &>/dev/null; then
        rustup-init -y
    fi

    setup_shell_common
    setup_ssh_keys

    log "macOS setup complete. Restart your terminal."
}

setup_wsl() {
    log "WSL setup"

    sudo apt-get update
    sudo apt-get install -y zsh git curl wget

    setup_shell_common

    if [ ! -d /tmp/powerline-fonts ]; then
        git clone --depth 1 https://github.com/powerline/fonts.git /tmp/powerline-fonts
        (cd /tmp/powerline-fonts && sudo bash install.sh)
    fi
    curl -fsSL https://raw.githubusercontent.com/seebi/dircolors-solarized/master/dircolors.ansi-dark -o ~/.dircolors

    setup_ssh_keys

    log "WSL setup complete. Restart your terminal (or run 'zsh')."
}

# Internal: runs the user-context steps (theme/aliases/ssh) as a specific
# user. Used by setup_linux_cloud after it has already elevated to root
# for the apt-get install step.
run_as_user_steps() {
    setup_shell_common
    setup_ssh_keys
}

setup_linux_cloud() {
    if [[ $EUID -ne 0 ]]; then
        log "Elevating to root for package installation"
        exec sudo "$(realpath "$0")" "$@"
    fi

    log "Linux (bare-metal/cloud GPU box) setup"

    sed -i 's/main$/main contrib non-free non-free-firmware/g' /etc/apt/sources.list 2>/dev/null || true
    if [ -f /etc/apt/sources.list.d/debian.sources ]; then
        sed -i 's/Components: main/Components: main contrib non-free non-free-firmware/g' /etc/apt/sources.list.d/debian.sources
    fi
    apt-get update
    apt-get install -y zsh curl wget git build-essential nvidia-cuda-toolkit cmake libssl-dev nvtop

    USER_NAME=${SUDO_USER:-$(logname)}
    chsh -s "$(which zsh)" "$USER_NAME"

    # Run the user-context steps (oh-my-zsh, theme, aliases, ssh keys) as the
    # real user, not root, by re-invoking this script.
    sudo -u "$USER_NAME" DOTFILES_INTERNAL_STEP=run_as_user_steps "$(realpath "$0")"

    # Rust, uv and Homebrew-on-Linux, as the real user
    sudo -u "$USER_NAME" bash << EOF
        curl -LsSf https://astral.sh/uv/install.sh | sh
        if ! command -v rustup &>/dev/null; then
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        fi
        if [ ! -d "/home/linuxbrew/.linuxbrew" ]; then
            /bin/bash -c "\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        if ! grep -q "brew shellenv" "\$HOME/.zshrc"; then
            echo 'eval "\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "\$HOME/.zshrc"
        fi
        eval "\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        brew install llama.cpp
EOF

    log "Linux cloud box setup complete. ZSH is now the default shell for $USER_NAME."
}

# --- Entry point ---

# Internal re-invocation hook (see setup_linux_cloud): when called this way,
# just run the requested user-context step and exit.
if [ "${DOTFILES_INTERNAL_STEP:-}" = "run_as_user_steps" ]; then
    run_as_user_steps
    exit 0
fi

case "$(uname -s)" in
    Darwin)
        setup_macos
        ;;
    Linux)
        if grep -qi microsoft /proc/version 2>/dev/null; then
            setup_wsl
        else
            setup_linux_cloud "$@"
        fi
        ;;
    *)
        echo "Unsupported OS: $(uname -s). Native Windows should use install.ps1 instead."
        exit 1
        ;;
esac
