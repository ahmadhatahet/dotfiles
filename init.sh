mkdir -p ~/.ssh
mv ~/dotfiles/ssh_config ~/.ssh/config

cat <<'EOF' >>~/.bashrc
# add dotfiles
source ~/dotfiles/aliases
EOF

source ~/.bashrc

echo '--Done--'
