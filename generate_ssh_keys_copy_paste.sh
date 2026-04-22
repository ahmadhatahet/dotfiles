bash << 'EOF'
# Define variables
CONFIG_FILE="$HOME/.ssh/config"

echo "Starting unified SSH setup process..."

# 1. Generate Ed25519 Keys (Overwriting existing)
echo -e "\nGenerating Ed25519 SSH keys..."

# GitLab Key
yes y | ssh-keygen -t ed25519 -f ~/.ssh/tuc_gitlab -N "" && \
echo "GitLab key generated: ~/.ssh/tuc_gitlab"

# GitHub Key
yes y | ssh-keygen -t ed25519 -f ~/.ssh/gh -N "" && \
echo "GitHub key generated: ~/.ssh/gh"

# 2. Generate SSH Config File
echo -e "\nUpdating SSH configuration file at $CONFIG_FILE..."

cat << CONFIG > "$CONFIG_FILE"
# --- GitLab (TU Clausthal) ---
Host github.com
    User git
    Hostname github.com
    PreferredAuthentications publickey
    IdentityFile ~/.ssh/gh
    IdentitiesOnly yes

Host gitlab.tu-clausthal.de
    HostName gitlab.tu-clausthal.de
    User ah19
    IdentityFile ~/.ssh/tuc_gitlab
    IdentitiesOnly yes

Host ai121
    HostName 139.174.67.121
    User ah19
    PreferredAuthentications password

Host ai122
    HostName 139.174.67.122
    User ah19
    PreferredAuthentications password

Host ai123
    HostName 139.174.67.123
    User ah19
    PreferredAuthentications password

Host ai124
    HostName 139.174.67.124
    User ah19
    PreferredAuthentications password

Host ai125
    HostName 139.174.67.125
    User ah19
    PreferredAuthentications password

Host a100_tuc
    HostName cloud-243.rz.tu-clausthal.de
    User ah19
    PreferredAuthentications password

Host h100_tuc
    HostName cloud-247.rz.tu-clausthal.de
    User ah19
    PreferredAuthentications password

# --- GitHub ---
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/gh
    IdentitiesOnly yes
CONFIG

# 3. Secure the files
chmod 700 ~/.ssh
chmod 600 "$CONFIG_FILE"
chmod 600 ~/.ssh/tuc_gitlab ~/.ssh/gh

echo -e "\nSetup Complete."
echo "--- Public Key for GitLab (Add to gitlab.tu-clausthal.de) ---"
cat ~/.ssh/tuc_gitlab.pub
echo -e "\n--- Public Key for GitHub (Add to github.com) ---"
cat ~/.ssh/gh.pub
EOF
