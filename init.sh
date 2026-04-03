#!/bin/bash

# 1. Hygiene: Fix Windows line endings and set permissions
find . -type f -name "*.sh" -exec sed -i 's/\r//g' {} +
chmod +x *.sh

echo "Step 1: Installing System Prerequisites..."
sudo apt-get update
sudo apt-get install -y build-essential procps curl file git

# 2. Install Homebrew (Linuxbrew)
if ! command -v brew &>/dev/null; then
    echo "Step 2: Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Inject Homebrew into the current shell session
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    
    # Make Brew persistent for future sessions (ZSH)
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.zshrc
fi

# 3. Install Rust via Rustup (Industry Standard)
if ! command -v rustup &>/dev/null; then
    echo "Step 3: Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# 4. Install llama.cpp with NVIDIA Support
echo "Step 4: Installing llama.cpp via Homebrew..."
# Ensure CUDA toolkit is present so Brew/Cmake can find it
sudo apt-get install -y nvidia-cuda-toolkit

# We attempt to install llama.cpp. 
# Note: If 'brew install' doesn't enable CUDA automatically, 
# use '--build-from-source' to force local compilation with your drivers.
brew install llama.cpp

# 5. Shell & SSH Finalization
echo "Step 5: Configuring Shell Environment..."

# Setup SSH
./generate_ssh_keys.sh
if [ -f "./ssh_config" ]; then
    mkdir -p ~/.ssh
    cp ./ssh_config ~/.ssh/config
fi

# Install uv for Python project management
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Oh-My-Zsh (Unattended)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Apply custom theme and source aliases
cp ./my_them.zsh-theme ~/.oh-my-zsh/custom/themes/
sed -i 's/ZSH_THEME="[^"]*"/ZSH_THEME="my_them"/' ~/.zshrc

# Link aliases to ZSH
if ! grep -q "source ~/dotfiles/aliases" ~/.zshrc; then
    echo "source ~/dotfiles/aliases" >> ~/.zshrc
fi

echo "--------------------------------------------------"
echo "Setup finished. Use 'exec zsh' to refresh."
echo "Verify llama.cpp with: llama-cli --version"
echo "--------------------------------------------------"
