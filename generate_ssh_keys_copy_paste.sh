bash << 'EOF'
echo "Starting SSH key generation process..."

# Generate key for GitLab
echo -e "\nGenerating SSH key for gitlab.tu-clausthal.de..."
ssh-keygen -t rsa -b 4096 -f ~/.ssh/tuc_gitlab -N "" && \
echo "GitLab key generated successfully: ~/.ssh/tuc_gitlab" || \
{ echo "Error generating GitLab key."; exit 1; }

# Generate key for GitHub
echo -e "\nGenerating SSH key for github.com..."
ssh-keygen -t rsa -b 4096 -f ~/.ssh/gh -N "" && \
echo "GitHub key generated successfully: ~/.ssh/gh" || \
{ echo "Error generating GitHub key."; exit 1; }

# Display Keys
echo -e "\n--- Public Key for GitLab ---"
cat ~/.ssh/tuc_gitlab.pub
echo -e "\n--- Public Key for GitHub ---"
cat ~/.ssh/gh.pub
EOF
