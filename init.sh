#!/bin/bash

mkdir -p ~/.ssh
mv ~/dotfiles/ssh_config ~/.ssh/config

cat <<'EOF' >>~/.bashrc
# add dotfiles
source ~/dotfiles/aliases
EOF

source ~/.bashrc

wget -qO- https://astral.sh/uv/install.sh | sh

echo '--Done--'
