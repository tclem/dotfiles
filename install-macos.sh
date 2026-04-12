#!/bin/bash
#
# macOS specific first time setup

set -euo pipefail

# Install Homebrew
if ! brew --version >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Initialize Homebrew for this script without relying on ~/.zprofile.
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Install everything in the Brewfile
brew bundle

# Prefer Homebrew zsh when available and set it as the account login shell.
target_shell=/bin/zsh
if [[ -x /opt/homebrew/bin/zsh ]]; then
    target_shell=/opt/homebrew/bin/zsh
elif [[ -x /usr/local/bin/zsh ]]; then
    target_shell=/usr/local/bin/zsh
fi

if ! grep -qx "$target_shell" /etc/shells; then
    echo "$target_shell" | sudo tee -a /etc/shells >/dev/null
fi

current_shell=$(dscl . -read /Users/$USER UserShell 2>/dev/null | awk '{print $2}')
if [[ "$current_shell" != "$target_shell" ]]; then
    chsh -s "$target_shell"
fi

if [[ ! -f ~/.cargo/config.toml ]]; then
    mkdir -p ~/.cargo
    echo "[net]\ngit-fetch-with-cli = true" > ~/.cargo/config.toml
fi

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
defaults write com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled -bool false
defaults delete -g ApplePressAndHoldEnabled

# iTerm2: load settings from a shared directory
defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "~/github/dotfiles/iterm2"
defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true
