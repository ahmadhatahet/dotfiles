sudo bash << 'EOF'
# Step 1: Repositories & Build Tools
echo "Updating repositories and installing build tools..."
sed -i 's/main$/main contrib non-free non-free-firmware/g' /etc/apt/sources.list
if [ -f /etc/apt/sources.list.d/debian.sources ]; then
    sed -i 's/Components: main/Components: main contrib non-free non-free-firmware/g' /etc/apt/sources.list.d/debian.sources
fi
apt-get update
apt-get install -y zsh curl wget git build-essential nvidia-cuda-toolkit cmake libssl-dev nvtop

# Step 2: User Context & Directory Setup
USER_NAME=${SUDO_USER:-$(logname)}
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)
DOTFILES_DIR="$USER_HOME/dotfiles"

echo "Creating dotfiles directory at $DOTFILES_DIR..."
mkdir -p "$DOTFILES_DIR"
cp -r ./* "$DOTFILES_DIR/"
chown -R "$USER_NAME:$USER_NAME" "$DOTFILES_DIR"

# Step 3: Shell Configuration
echo "Setting ZSH as default shell..."
chsh -s $(which zsh) "$USER_NAME"

# Oh-My-Zsh Installation (Non-interactive)
sudo -u "$USER_NAME" bash <<SUBEOF
    if [ ! -d "\$HOME/.oh-my-zsh" ]; then
        sh -c "\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
SUBEOF

# Apply Theme & Aliases
if [ -f "$DOTFILES_DIR/my_them.zsh-theme" ]; then
    cp -f "$DOTFILES_DIR/my_them.zsh-theme" "$USER_HOME/.oh-my-zsh/custom/themes/"
    chown "$USER_NAME:$USER_NAME" "$USER_HOME/.oh-my-zsh/custom/themes/my_them.zsh-theme"
    sed -i 's/ZSH_THEME="[^"]*"/ZSH_THEME="my_them"/' "$USER_HOME/.zshrc"
fi

if [ -f "$DOTFILES_DIR/aliases" ] && ! grep -q "source $DOTFILES_DIR/aliases" "$USER_HOME/.zshrc"; then
    echo "source $DOTFILES_DIR/aliases" >> "$USER_HOME/.zshrc"
fi

# Step 4: Toolchain & Homebrew
sudo -u "$USER_NAME" bash <<SUBEOF
    curl -LsSf https://astral.sh/uv/install.sh | sh
    if ! command -v rustup &>/dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fi
    if [ ! -d "/home/linuxbrew/.linuxbrew" ]; then
        /bin/bash -c "\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Permanent Brew Activation
    BREW_LINE='eval "\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
    grep -qF "\$BREW_LINE" "\$HOME/.bashrc" || echo "\$BREW_LINE" >> "\$HOME/.bashrc"
    grep -qF "\$BREW_LINE" "\$HOME/.zshrc" || echo "\$BREW_LINE" >> "\$HOME/.zshrc"

    eval "\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    brew install llama.cpp
SUBEOF

echo "Setup complete! Transitioning to ZSH..."
exec sudo -u "$USER_NAME" -i zsh
EOF
