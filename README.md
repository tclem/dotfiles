# tclem and his dotfiles

These are my dotfiles.

## Install

Targets **macOS** (Homebrew) and **Linux** (Ubuntu/Debian, WIP).

``` sh
./install.sh
```

This detects your OS, installs packages, symlinks configs (`.zshrc`, `tmux.conf`), sets up git, and syncs Copilot config.

Put secrets and machine-specific overrides in `~/.localrc` (not versioned).

---

Originally forked from [Zach Holman's dotfiles](https://github.com/holman/dotfiles), but I've diverged dramatically over the years. Many zsh tricks borrowed from [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh).
