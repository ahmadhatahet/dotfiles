#!/bin/bash

echo "Starting SSH key generation process..."

# --- Generate key for GitLab (tu-clausthal.de) ---
echo -e "\nGenerating SSH key for gitlab.tu-clausthal.de..."
ssh-keygen -t rsa -b 4096 -f ~/.ssh/tuc_gitlab -N ""

if [ $? -eq 0 ]; then
    echo "GitLab key generated successfully: ~/.ssh/tuc_gitlab"
else
    echo "Error generating GitLab key. Exiting."
    exit 1
fi

# --- Generate key for GitHub ---
echo -e "\nGenerating SSH key for github.com..."
ssh-keygen -t rsa -b 4096 -f ~/.ssh/gh -N ""

if [ $? -eq 0 ]; then
    echo "GitHub key generated successfully: ~/.ssh/gh"
else
    echo "Error generating GitHub key. Exiting."
    exit 1
fi

# --- Display Public Keys ---
echo -e "\n--- Public Key for GitLab (gitlab.tu-clausthal.de) ---"
echo "Copy the following key and add it to your GitLab account settings (User Settings -> SSH Keys):"
cat ~/.ssh/tuc_gitlab.pub

echo -e "\n--- Public Key for GitHub (github.com) ---"
echo "Copy the following key and add it to your GitHub account settings (Settings -> SSH and GPG keys):"
cat ~/.ssh/gh.pub

echo -e "\nSSH key generation and display complete. Remember to add these public keys to your respective accounts!"
