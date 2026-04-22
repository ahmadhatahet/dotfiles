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

Host gitlab.example.org
    HostName gitlab.example.org
    User redacted-user
    IdentityFile ~/.ssh/tuc_gitlab
    IdentitiesOnly yes

Host ai121
    HostName 203.0.113.121
    User redacted-user
    PreferredAuthentications password

Host ai122
    HostName 203.0.113.122
    User redacted-user
    PreferredAuthentications password

Host ai123
    HostName 203.0.113.123
    User redacted-user
    PreferredAuthentications password

Host ai124
    HostName 203.0.113.124
    User redacted-user
    PreferredAuthentications password

Host ai125
    HostName 203.0.113.125
    User redacted-user
    PreferredAuthentications password

Host a100_tuc
    HostName cloud-243.rz.example.org
    User redacted-user
    PreferredAuthentications password

Host h100_tuc
    HostName cloud-247.rz.example.org
    User redacted-user
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
echo "--- Public Key for GitLab (Add to gitlab.example.org) ---"
cat ~/.ssh/tuc_gitlab.pub
echo -e "\n--- Public Key for GitHub (Add to github.com) ---"
cat ~/.ssh/gh.pub
EOF
