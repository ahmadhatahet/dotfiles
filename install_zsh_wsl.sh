# navigate to home
cd ~

# install zsh
sudo apt-get install zsh -y

# install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# change default them
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="bira"/g' ~/.zshrc

# add developers fonts
git clone https://github.com/powerline/fonts.git

# install fonst
cd fonts
sudo bash install.sh

# using dircolors.ansi-dark
cd ~
curl https://raw.githubusercontent.com/seebi/dircolors-solarized/master/dircolors.ansi-dark --output ~/.dircolors

cp ~/dotfiles/my_them.zsh-theme ~/.oh-my-zsh/custom/themes/my_them.zsh-theme
sed -i '' 's/ZSH_THEME="[^"]*"/ZSH_THEME="my_theme"/' ~/.zshrc



source ~/.zshrc
