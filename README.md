# tclem and his dotfiles

These are my dotfiles.

## Install

macOS/Linux:

```sh
./install.sh
script/configure-blackbird [on|remote-only|off|status]
```

Windows (PowerShell 7):

```powershell
.\install.ps1
.\script\configure-blackbird.ps1 [on|remote-only|off|status]
```

Windows uses `Q:\` as `$PROJECTS`. Blackbird defaults to `remote-only`; omitting the mode restores that default.

Put secrets and machine-specific overrides in `~/.localrc` (not versioned).

---

Originally forked from [Zach Holman's dotfiles](https://github.com/holman/dotfiles), but I've diverged dramatically over the years. Many zsh tricks borrowed from [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh).
