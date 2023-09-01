if [[ -n $SSH_CONNECTION ]]; then
  export PS1='%m:%3~$(git_info_for_prompt)%# '
else
  export PS1='%3~$(git_info_for_prompt)%# '
fi

# export TERM='xterm-color'
# export LSCOLORS='cat ~/.dir_colors'
# export LSCOLORS="exfxcxdxbxegedabagacad"
export CLICOLOR=true
# export ZLSCOLORS="${LS_COLORS}"

fpath=($ZSH/zsh/functions $fpath)
autoload -U $ZSH/zsh/functions/*(:t)

HISTFILE=~/.zsh_history
# HISTSIZE=1000
# SAVEHIST=1000
HISTSIZE=99999
# HISTFILESIZE=999999
SAVEHIST=$HISTSIZE

setopt NO_BG_NICE # don't nice background tasks
setopt NO_HUP
setopt NO_LIST_BEEP
setopt LOCAL_OPTIONS # allow functions to have local options
setopt LOCAL_TRAPS # allow functions to have local traps
setopt HIST_VERIFY
# setopt SHARE_HISTORY # share history between sessions ???
setopt EXTENDED_HISTORY # add timestamps to history
setopt PROMPT_SUBST
setopt CORRECT
setopt COMPLETE_IN_WORD
setopt IGNORE_EOF

setopt APPEND_HISTORY # adds history
setopt INC_APPEND_HISTORY # adds history incrementally
setopt HIST_IGNORE_ALL_DUPS  # don't record dupes in history
setopt HIST_REDUCE_BLANKS

zle -N newtab

bindkey '^[^[[D' backward-word
bindkey '^[^[[C' forward-word
bindkey '^[[5D' beginning-of-line
bindkey '^[[5C' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[^N' newtab
bindkey '^?' backward-delete-char

# GRC colorizes nifty unix tools all over the place
if $(gls &>/dev/null)
then
  source `brew --prefix`/etc/grc.bashrc
fi

# Color grep results
# export GREP_OPTIONS='--color=auto'
alias grep='grep --color=auto'

# key bindings
bindkey ' ' magic-space    # also do history expansion on space

export EDITOR=vi
export LETTER_OPENER=1
