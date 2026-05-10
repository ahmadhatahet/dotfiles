#!/bin/bash

# --- SELF-ELEVATION ---
if [[ $EUID -ne 0 ]]; then
   SCRIPT_PATH=$(realpath "$0")
   exec sudo "$SCRIPT_PATH" "$@"
fi

# Step 1: Repositories, Build Tools & Monitoring
echo "Step 1: Updating repositories and installing system tools..."
sed -i 's/main$/main contrib non-free non-free-firmware/g' /etc/apt/sources.list
if [ -f /etc/apt/sources.list.d/debian.sources ]; then
    sed -i 's/Components: main/Components: main contrib non-free non-free-firmware/g' /etc/apt/sources.list.d/debian.sources
fi
apt-get update
# Moved nvtop and libssl-dev here where root access is available
apt-get install -y zsh curl wget git build-essential nvidia-cuda-toolkit cmake libssl-dev nvtop

# Step 2: User Context & Directory Setup
USER_NAME=${SUDO_USER:-$(logname)}
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)
DOTFILES_DIR="$USER_HOME/dotfiles"

echo "Syncing dotfiles to $DOTFILES_DIR..."
mkdir -p "$DOTFILES_DIR"
cp -r ./* "$DOTFILES_DIR/"

# --- GENERATE THE CALM THEME FILE ---
cat << 'EOF' > "$DOTFILES_DIR/my_them.zsh-theme"
PROMPT=""
NEWLINE=$'\n'

function git_prompt_info() {
  local ref=$(git symbolic-ref HEAD 2> /dev/null) || \
  local ref=$(git rev-parse --short HEAD 2> /dev/null) || return
  echo "%B%F{242}|%f%b%F{78}${ref#refs/heads/}%f"
}

# Line 1: User/Host (Blue), Path (Cyan), Git (Muted Green)
# Line 2: Emerald Arrow
PROMPT='%F{111}%n%f@%F{111}%m%f:%F{81}%~%B$(git_prompt_info)%b ${NEWLINE}%F{78}»%f '
RPS1='%(?..%F{242}× %?%f)'
EOF

chown -R "$USER_NAME:$USER_NAME" "$DOTFILES_DIR"

# Step 3: Shell Configuration
echo "Configuring ZSH as permanent default shell..."
chsh -s $(which zsh) "$USER_NAME"

# Oh-My-Zsh Installation (as User)
sudo -u "$USER_NAME" bash <<EOF
    if [ ! -d "\$HOME/.oh-my-zsh" ]; then
        sh -c "\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
EOF

# Deploy Theme from Dotfiles to Oh-My-Zsh
cp -f "$DOTFILES_DIR/my_them.zsh-theme" "$USER_HOME/.oh-my-zsh/custom/themes/"
chown "$USER_NAME:$USER_NAME" "$USER_HOME/.oh-my-zsh/custom/themes/my_them.zsh-theme"

# Link .zshrc settings
sed -i 's/ZSH_THEME="[^"]*"/ZSH_THEME="my_them"/' "$USER_HOME/.zshrc"
if ! grep -q "source $DOTFILES_DIR/aliases" "$USER_HOME/.zshrc"; then
    echo "source $DOTFILES_DIR/aliases" >> "$USER_HOME/.zshrc"
fi

# Step 4: Toolchain & Homebrew Pathing
sudo -u "$USER_NAME" bash <<EOF
    # 1. uv
    curl -LsSf https://astral.sh/uv/install.sh | sh

    # 2. Rust
    if ! command -v rustup &>/dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fi

    # 3. Homebrew
    if [ ! -d "/home/linuxbrew/.linuxbrew" ]; then
        /bin/bash -c "\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # 4. Permanent Brew Activation
    echo >> "\$HOME/.bashrc"
    echo 'eval "\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "\$HOME/.bashrc"
    
    if ! grep -q "brew shellenv" "\$HOME/.zshrc"; then
        echo 'eval "\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "\$HOME/.zshrc"
    fi

    eval "\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    
    # 5. llama.cpp
    brew install llama.cpp
EOF

echo "--------------------------------------------------"
echo "Setup complete! nvtop and llama.cpp are ready."
echo "ZSH is your permanent shell with the calm theme."
echo "--------------------------------------------------"

exec sudo -u "$USER_NAME" -i zsh


# --- System & Navigation ---
alias adddotfilestobash='cat <<'\''EOF'\'' >>~/.bashrc
# add dotfiles
source ~/dotfiles/.aliases
EOF'
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
alias cpdotfiles='cp "/mnt/d/scripts/dotfiles/aliases" $HOME/dotfiles/.aliases'
alias cpssh='cp "/mnt/d/scripts/dotfiles/ssh_config" $HOME/.ssh/ssh_config &&\
mv $HOME/.ssh/ssh_config $HOME/.ssh/config'
alias devdir='cd /mnt/d/scripts/'
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

# --- Development Tools ---
alias uv='uv'
alias rust-update='rustup update'
alias brew-up='brew update && brew upgrade'
