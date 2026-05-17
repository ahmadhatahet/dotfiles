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
brew "python"
brew "nodejs"
brew "openjdk"
brew "golang"
brew "rust"
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
cask "iina"
cask "maccy"
EOF

# 2. Write the Homebrew dependencies directly to your persistent Brewfile
cat << 'EOF' > ~/dotfiles/aliases
# --- System & Navigation ---
alias explorer='explorer.exe .'
alias home='cd ~'
alias jp='jupyter notebook --port 5668 --no-browser'
alias jpl='jupyter lab --port 5669 --no-browser'
alias l='ls -CF'
alias la='ls -la'
alias ll='ls -l'
alias ls='ls --color=auto'
alias wnv='watch -n 3 nvidia-smi'

# --- Git Shortcuts (Software Engineering Standard) ---
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit -m'
alias gca='git commit --amend --no-edit'
alias gp='git push'
alias gpl='git pull'
alias gl='git log --oneline --graph --decorate'
alias gld="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias gd='git diff'
alias gds='git diff --staged'
alias gb='git branch'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gm='git merge'
alias gr='git remote -v'
alias gst='git stash'
alias gstp='git stash pop'

# --- Advanced Git Sync & Rebase ---
alias gup='git pull --rebase'             # Update local branch by reapplying commits on top of upstream
alias gpu='git push -u origin $(git branch --show-current)' # Push and set upstream for new branches
alias gf='git fetch --all --prune'        # Fetch all branches and remove references to deleted ones
alias gcan='git commit --amend --no-edit' # Quickly fix the last commit without changing the message

# --- Navigation & Branching ---
alias gco='git checkout'
alias gcb='git checkout -b'
alias gcm='git checkout main || git checkout master' # Jump to the primary branch
alias gbd='git branch -d'                 # Delete a merged branch
alias gbD='git branch -D'                 # Force delete an unmerged branch

# --- Inspection & Cleanup ---
alias gsh='git show'                      # Inspect the changes in the most recent commit
alias gst='git status -sb'                # Short, branch-aware status
alias gcp='git cherry-pick'               # Bring a specific commit from another branch
alias gclean='git clean -fd'              # Remove untracked files and directories (dangerous but useful)
alias grh='git reset --hard'              # Wipe local changes (the "nuclear" option)
alias grs='git reset --soft HEAD~1'       # Undo last commit but keep your changes staged

# --- Conflict Resolution ---
alias gm='git merge'
alias gmt='git mergetool'                 # Launch your configured diff tool for conflicts
alias grba='git rebase --abort'           # Safely exit a messy rebase
alias grbc='git rebase --continue'        # Move to the next step after resolving rebase conflicts
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
