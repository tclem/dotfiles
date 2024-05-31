#!/bin/bash
#
# macOS specific first time setup

set -euo pipefail

# Install Homebrew
if ! brew --version; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install everything in the Brewfile
brew bundle

# Configure MacOS

# Fast keyrepeat
defaults write -g InitialKeyRepeat -int 15 # normal minimum is 15 (225 ms)
defaults write -g KeyRepeat -int 1 # normal minimum is 2 (30 ms)

# Disable Accent Menu when you hold down a key
defaults write -g ApplePressAndHoldEnabled -bool false

# Hide desktop icons
defaults write com.apple.finder CreateDesktop false; killall Finder

# Dock on the right
defaults write com.apple.dock autohide -int 1; defaults write com.apple.dock orientation -string right; killall Dock

# VSCode Vim
defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false
defaults delete -g ApplePressAndHoldEnabled

# iTerm2: load settings from a shared directory
defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "~/github/dotfiles/iterm2"
defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true
