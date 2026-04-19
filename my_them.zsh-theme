# 1. Download the Font to Windows Downloads (so you can install it manually)
echo "Downloading MesloLGS NF Regular.ttf to Windows Downloads..."
curl -L "https://github.com/romkatv/dotfiles-public/raw/master/font/MesloLGS%20NF%20Regular.ttf" -o "/mnt/c/Users/$USER/Downloads/MesloLGS_NF_Regular.ttf" 2>/dev/null || \
curl -L "https://github.com/romkatv/dotfiles-public/raw/master/font/MesloLGS%20NF%20Regular.ttf" -o "./MesloLGS_NF_Regular.ttf"

# 2. Setup Powerlevel10k
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
fi
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc

# 3. Completion System Cleanup (Fixing the compinit error)
echo "Cleaning up Zsh completion cache..."
rm -f ~/.zcompdump*

# 4. Inject Final Styling & Logic
sed -i '/# P10K_START/,/# P10K_END/d' ~/.zshrc

cat << 'EOF' >> ~/.zshrc
# P10K_START
typeset -g POWERLEVEL9K_MODE='nerdfont-complete'
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true

# Icons and OS (Linux Logo)
typeset -g POWERLEVEL9K_OS_ICON_CONTENT_EXPANSION='' 
typeset -g POWERLEVEL9K_OS_ICON_BACKGROUND=24
typeset -g POWERLEVEL9K_OS_ICON_FOREGROUND=255

# Directory & VCS (Clean Blue)
typeset -g POWERLEVEL9K_DIR_BACKGROUND=31
typeset -g POWERLEVEL9K_DIR_FOREGROUND=255

# The Connected "Branch" Layout
typeset -g POWERLEVEL9K_PROMPT_ON_NEWLINE=true
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX='╭─'
typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX='╰─ '
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon dir vcs)
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status time)

# Visual Separators & Time
typeset -g POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR='\uE0B0'
typeset -g POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR='\uE0B2'
typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%I:%M:%S %p}'
typeset -g POWERLEVEL9K_TIME_BACKGROUND=24
typeset -g POWERLEVEL9K_TIME_FOREGROUND=255
# P10K_END
EOF

# 5. Finalize and Reload
echo "Configuration applied. Running 'exec zsh' to refresh..."
exec zsh
