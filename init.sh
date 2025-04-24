mkdir -p ~/dotfiles
# mkdir -p ~/.ssh

cp "/mnt/d/ownCloud/dotfiles/aliases" ~/dotfiles/.aliases
cp "/mnt/d/ownCloud/dotfiles/ssh_config" ~/.ssh/ssh_config
mv ~/.ssh/ssh_config ~/.ssh/config

cat <<'EOF' >>~/.bashrc
# add dotfiles
source ~/dotfiles/.aliases
EOF

source ~/.bashrc

echo '--Done--'