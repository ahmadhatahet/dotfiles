#!/bin/bash
set -e # Exit on error

# 1. Hygiene & Early Dependencies
find . -type f -name "*.sh" -exec sed -i 's/\r//g' {} +
chmod +x *.sh
sudo apt-get update
sudo apt-get install -y zsh curl wget git build-essential nvidia-cuda-toolkit

# 2. Shell Setup (ZSH First)
echo "Step 2: Configuring ZSH & Oh-My-Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Apply theme and link aliases immediately
cp ./my_them.zsh-theme ~/.oh-my-zsh/custom/themes/
sed -i 's/ZSH_THEME="[^"]*"/ZSH_THEME="my_them"/' ~/.zshrc

if ! grep -q "source ~/dotfiles/aliases" ~/.zshrc; then
    echo "source ~/dotfiles/aliases" >> ~/.zshrc
fi

# 3. Security (SSH Generation)
echo "Step 3: Generating SSH Keys..."
./generate_ssh_keys.sh
[ -f "./ssh_config" ] && cp ./ssh_config ~/.ssh/config

# 4. Tooling (uv, Brew, Rust)
echo "Step 4: Installing Heavy Tooling (uv, Brew, Rust)..."

# uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Homebrew
if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.zshrc
fi

# Rust
if ! command -v rustup &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# 5. Application (llama.cpp)
echo "Step 5: Installing llama.cpp..."
brew install llama.cpp

echo "--------------------------------------------------"
echo "Setup finished. Your ZSH environment is ready."
echo "Run 'exec zsh' to apply all changes."
echo "--------------------------------------------------"
