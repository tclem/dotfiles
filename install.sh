#!/bin/bash
#
# Install all the things

set -euo pipefail

if [[ -f ~/.dotfilesv && $(cat ~/.dotfilesv) = $(git rev-parse HEAD) ]]; then
  exit 1
fi

if [[ "$(uname -s)" = "Darwin" ]]; then
    ./install-macos.sh
    echo "This is a good time to create a GitHub PAT, create ~/.netrc and ~/.localrc"
    read -p "Press enter to continue"
else
    echo "Linux install is a WIP"
fi

gh alias import gh/aliases.yml

# Setup .zshrc
rm -rf ~/.zshrc
ln -s "$(pwd)/.zshrc" ~/.zshrc

# Ruby
# git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
# rbenv install 3.3.1
# rbenv global 3.3.1

# lazy vim
# git clone https://github.com/LazyVim/starter ~/.config/nvim

# Setup git
git config --global user.name 'Timothy Clem'
git config --global user.email 'timothy.clem@gmail.com'
git config --global github.user 'tclem'
if [[ "$(uname -s)" = "Darwin" ]]; then
  git config --global credential.helper osxkeychain
fi
git config --global alias.co checkout
git config --global alias.lo 'log --oneline --decorate'
git config --global alias.lol 'log --oneline --graph --decorate'
git config --global alias.last 'log -1 HEAD'
git config --global alias.first 'log --reverse --pretty=format:"%h %ad%x09%an%x09%s" --date=short | grep Clem | head -1'
git config --global pull.rebase true
git config --global push.default simple

# write out a manifest of the installed dotfiles version: delete this file to force a re-install
git rev-parse HEAD > ~/.dotfilesv
