# 1. Ensure your local dotfiles directory exists
mkdir -p ~/dotfiles

# 2. Write the Homebrew dependencies directly to your persistent Brewfile
cat << 'EOF' > ~/dotfiles/Brewfile
# --- Core Development Tooling ---
brew "cmake"
brew "gcc"
brew "git"
brew "make"
brew "rustup"
brew "uv"
brew "swi-prolog"
brew "xcodegen"

# --- System & Hardware Monitors ---
brew "htop"
brew "nvtop"

# --- Machine Learning / Inference ---
brew "llama.cpp"

# --- Containers & Virtualization ---
cask "podman-desktop"
brew "docker"

# --- GUI Applications & Enhancements (Casks) ---
cask "iterm2"
cask "drawpen"
cask "middleclick"
EOF

# 3. Create the automated macOS setup script
cat << 'EOF' > ~/dotfiles/init_mac.sh
#!/bin/zsh

echo "--- Starting macOS Developer Setup ---"
DOTFILES_DIR="$HOME/dotfiles"

# Step 1: Install Homebrew if it's missing
if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
fi

# Activate Brew environment for the current execution
eval "$(/opt/homebrew/bin/brew shellenv)"

# Step 2: Install all Brewfile dependencies natively
echo "Installing ecosystem from Brewfile..."
if [ -f "$DOTFILES_DIR/Brewfile" ]; then
    brew bundle --file="$DOTFILES_DIR/Brewfile"
else
    echo "Warning: Brewfile not found in $DOTFILES_DIR"
fi

# Step 3: Initialize the Rust Toolchain if not active
if command -v rustup-init &>/dev/null; then
    rustup-init -y
fi

# Step 4: Setup Oh-My-Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh-My-Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Step 5: Write the Calm Emerald Theme
echo "Deploying calm terminal theme..."
cat << 'THEME' > "$HOME/.oh-my-zsh/custom/themes/my_them.zsh-theme"
PROMPT=""
NEWLINE=$'\n'
function git_prompt_info() {
  local ref=$(git symbolic-ref HEAD 2> /dev/null) || return
  echo "%B%F{242}|%f%b%F{78}${ref#refs/heads/}%f"
}
PROMPT='%F{111}%n%f@%F{111}%m%f:%F{81}%~%B$(git_prompt_info)%b ${NEWLINE}%F{78}»%f '
RPS1='%(?..%F{242}× %?%f)'
THEME

# Step 6: Link configurations permanently to .zshrc
sed -i '' 's/ZSH_THEME="[^"]*"/ZSH_THEME="my_them"/' ~/.zshrc

if ! grep -q "source ~/dotfiles/aliases" ~/.zshrc; then
    echo "source ~/dotfiles/aliases" >> ~/.zshrc
fi

echo "--- Setup Complete! Your environment is ready. ---"
# Instantly drop into your clean Zsh configuration
exec zsh
EOF

# 4. Correct execution permissions and launch the script
chmod +x ~/dotfiles/init_mac.sh
~/dotfiles/init_mac.sh
