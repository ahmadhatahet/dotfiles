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

# Step 2: User Context & Directory Setup
USER_NAME=${SUDO_USER:-$(logname)}
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)
DOTFILES_DIR="$USER_HOME/dotfiles"

echo "Creating dotfiles directory at $DOTFILES_DIR..."
mkdir -p "$DOTFILES_DIR"
# Copy all files from the current directory to ~/dotfiles
cp -r ./* "$DOTFILES_DIR/"
chown -R "$USER_NAME:$USER_NAME" "$DOTFILES_DIR"

# Step 3: Shell Configuration (Permanent ZSH)
echo "Setting ZSH as default shell..."
chsh -s $(which zsh) "$USER_NAME"

# Oh-My-Zsh Installation
sudo -u "$USER_NAME" bash <<EOF
    if [ ! -d "\$HOME/.oh-my-zsh" ]; then
        sh -c "\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
EOF

# Apply Theme & Aliases to .zshrc
cp -f "$DOTFILES_DIR/my_them.zsh-theme" "$USER_HOME/.oh-my-zsh/custom/themes/"
chown "$USER_NAME:$USER_NAME" "$USER_HOME/.oh-my-zsh/custom/themes/my_them.zsh-theme"

# Ensure .zshrc points to the new persistent location
sed -i 's/ZSH_THEME="[^"]*"/ZSH_THEME="my_them"/' "$USER_HOME/.zshrc"
if ! grep -q "source $DOTFILES_DIR/aliases" "$USER_HOME/.zshrc"; then
    echo "source $DOTFILES_DIR/aliases" >> "$USER_HOME/.zshrc"
fi

# Step 4: Toolchain & Homebrew Pathing
sudo -u "$USER_NAME" bash <<EOF
    # 1. Install uv
    curl -LsSf https://astral.sh/uv/install.sh | sh

    # 2. Install Rust
    if ! command -v rustup &>/dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fi

    # 3. Install Homebrew
    if [ ! -d "/home/linuxbrew/.linuxbrew" ]; then
        /bin/bash -c "\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # 4. Permanent Brew Activation (Bash & Zsh)
    echo >> "\$HOME/.bashrc"
    echo 'eval "\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "\$HOME/.bashrc"
    
    # Also add to .zshrc so it works in your new default shell
    if ! grep -q "brew shellenv" "\$HOME/.zshrc"; then
        echo 'eval "\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "\$HOME/.zshrc"
    fi

    # Activate for the current subshell to finish llama.cpp
    eval "\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    
    # 5. Install llama.cpp
    brew install llama.cpp
    apt install -y libssl-dev nvtop
EOF

echo "--------------------------------------------------"
echo "Setup complete! Your files are now in $DOTFILES_DIR"
echo "ZSH is now your permanent default shell."
echo "--------------------------------------------------"

# Transition to the user's new environment
exec sudo -u "$USER_NAME" -i zsh
