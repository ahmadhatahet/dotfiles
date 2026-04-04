#!/bin/bash

# --- SELF-ELEVATION ---
if [[ $EUID -ne 0 ]]; then
   SCRIPT_PATH=$(realpath "$0")
   exec sudo "$SCRIPT_PATH" "$@"
fi

# Step 1: Repositories & Build Tools
sed -i 's/main$/main contrib non-free non-free-firmware/g' /etc/apt/sources.list
if [ -f /etc/apt/sources.list.d/debian.sources ]; then
    sed -i 's/Components: main/Components: main contrib non-free non-free-firmware/g' /etc/apt/sources.list.d/debian.sources
fi
apt-get update
apt-get install -y zsh curl wget git build-essential nvidia-cuda-toolkit cmake

# Step 2: User Context Setup
USER_NAME=${SUDO_USER:-$(logname)}
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)

# Oh-My-Zsh
sudo -u "$USER_NAME" bash <<EOF
    [ ! -d "\$HOME/.oh-my-zsh" ] && sh -c "\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
EOF

# Theme & Aliases
cp -f ./my_them.zsh-theme "$USER_HOME/.oh-my-zsh/custom/themes/"
chown "$USER_NAME:$USER_NAME" "$USER_HOME/.oh-my-zsh/custom/themes/my_them.zsh-theme"
sed -i 's/ZSH_THEME="[^"]*"/ZSH_THEME="my_them"/' "$USER_HOME/.zshrc"

if ! grep -q "source ~/dotfiles/aliases" "$USER_HOME/.zshrc"; then
    echo "source ~/dotfiles/aliases" >> "$USER_HOME/.zshrc"
    chown "$USER_NAME:$USER_NAME" "$USER_HOME/.zshrc"
fi

# Step 3: The Toolchain (The Fix)
sudo -u "$USER_NAME" bash <<EOF
    # 1. Install uv
    curl -LsSf https://astral.sh/uv/install.sh | sh

    # 2. Install Rust & Source immediately for this subshell
    if ! command -v rustup &>/dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        . "\$HOME/.cargo/env"
    fi

    # 3. Install Homebrew
    if [ ! -d "/home/linuxbrew/.linuxbrew" ]; then
        /bin/bash -c "\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # 4. Use Absolute Path for Brew to install llama.cpp
    # This bypasses the 'command not found' error
    /home/linuxbrew/.linuxbrew/bin/brew install llama.cpp
EOF

echo "--------------------------------------------------"
echo "Setup finalized successfully!"
echo "Switching you to your new ZSH environment now..."
echo "--------------------------------------------------"

# Automatically drop the user into their new shell
exec sudo -u "$USER_NAME" -i zsh
