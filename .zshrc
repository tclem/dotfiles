export LETTER_OPENER=1
export PATH=$HOME/go/bin:$PATH # Go binaries
export PATH="$HOME/.cargo/bin:$PATH" # Rust cargo
export PATH="$HOME/.local/bin:$PATH"
export PATH=":bin:$PATH"

# your project folder that we can `c [tab]` to
case `uname` in
  Darwin)
    eval "$(/opt/homebrew/bin/brew shellenv)"
    prefix=$(brew --prefix)

    # commands for OS X go here
    export PROJECTS=~/github
    export ZSH=$PROJECTS/dotfiles
    export EDITOR=vi
    export SHELL=$prefix/bin/zsh
    # Homebrew's zsh completions (some packages install here too)
    FPATH="$prefix/share/zsh/site-functions:${FPATH}"

    export MANPATH="$prefix/man:$prefix/mysql/man:$prefix/git/man:$MANPATH"
    export PATH="$prefix/bin:$ZSH/bin:$PATH" # homebrew
    export PATH="$prefix/opt/mysql-client/bin:$PATH" # mysql
    export PATH="/usr/local/bin:$PATH" # docker and a few other utils
    # export PATH="/usr/local/go/bin:$PATH" # Manual install of Go to fix "was built for newer 'macOS' version (15.4) than being linked (15.0)" warnings
    # export PATH="$HOME/.docker/bin:$PATH" # docker
    # export PATH="$prefix/opt/python@3.8/libexec/bin:$PATH"
    # export PATH="$prefix/opt/node@10/bin:$PATH"
    # export PATH="$PATH:./node_modules/.bin"
  ;;
  Linux)
    # commands for Linux go here (mostly codespaces for me)
    export PROJECTS=/workspaces
    export ZSH=/workspaces/.codespaces/.persistedshare/dotfiles
    export SHELL=/bin/zsh
  ;;
esac

# use .localrc for SUPER SECRET CRAP that you don't want in your public, versioned repo.
if [[ -a ~/.localrc ]]; then
  source ~/.localrc
fi

HISTFILE=~/.zsh_history
HISTSIZE=99999
SAVEHIST=$HISTSIZE

# Custom functions defined in this repo
FPATH="$ZSH/zsh/functions:${FPATH}"
autoload -U $ZSH/zsh/functions/*(:t)

# Do this once
autoload -Uz compinit
compinit

# zsh options
setopt ALWAYS_TO_END
setopt AUTO_CD   # If a command is issued that can’t be executed as a normal command, and the command is the name of a directory, perform the cd command to that directory
setopt AUTO_LIST # Automatically list choices on an ambiguous completion.
setopt AUTO_MENU # show completion menu on succesive tab press
setopt COMPLETE_IN_WORD
setopt NO_BG_NICE # don't nice background tasks
# setopt NO_HUP
# setopt NO_LIST_BEEP
# setopt LOCAL_OPTIONS # allow functions to have local options
# setopt LOCAL_TRAPS # allow functions to have local traps
# setopt HIST_VERIFY
# # setopt SHARE_HISTORY # share history between sessions ???
setopt EXTENDED_HISTORY # add timestamps to history
setopt PROMPT_SUBST # parameter expansion, command substitution and arithmetic expansion are performed in prompts
# setopt CORRECT
# setopt IGNORE_EOF
setopt APPEND_HISTORY # adds history
setopt INC_APPEND_HISTORY # adds history incrementally
setopt HIST_IGNORE_ALL_DUPS  # don't record dupes in history
setopt HIST_REDUCE_BLANKS
# zle -N newtab
bindkey -e # emacs
# bindkey '^[^[[D' backward-word
# bindkey '^[^[[C' forward-word
# bindkey '^[[5D' beginning-of-line
# bindkey '^[[5C' end-of-line
# bindkey '^[[3~' delete-char
# bindkey '^[^N' newtab
# bindkey '^?' backward-delete-char
# bindkey ' ' magic-space
# setopt multios
# setopt cdablevarS
# autoload -U edit-command-line
# zle -N edit-command-line
# bindkey '^Xe' edit-command-line

# Enable ls colors
autoload colors; colors;
export CLICOLOR=true
# export LSCOLORS="Gxfxcxdxbxegedabagacad"
# export LSCOLORS="ExFxBxDxCxegedabagacad"
# if [ "$DISABLE_LS_COLORS" != "true" ]; then
#   # Find the option for using colors in ls, depending on the version: Linux or BSD
#   ls --color -d . &>/dev/null 2>&1 && alias ls='ls --color=tty' || alias ls='ls -G'
# fi
# # GRC colorizes nifty unix tools all over the place
if $(gls &>/dev/null); then
  source `brew --prefix`/etc/grc.zsh
fi

# Completions
zmodload -i zsh/complist
bindkey -M menuselect '^o' accept-and-infer-next-history
zstyle ':completion:*:*:*:*:*' menu select                                                 # highlight the selection
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*' # case-insensitive (all),partial-word and then substring completion
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories   # disable named-directories autocompletion
cdpath=(.)
# zstyle ':completion:*' list-colors ''
# zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:*:*:processes' command "ps -u `whoami` -o pid,user,comm -w -w"
# use /etc/hosts and known_hosts for hostname completion
[ -r ~/.ssh/known_hosts ] && _ssh_hosts=(${${${${(f)"$(<$HOME/.ssh/known_hosts)"}:#[\|]*}%%\ *}%%,*}) || _ssh_hosts=()
[ -r /etc/hosts ] && : ${(A)_etc_hosts:=${(s: :)${(ps:\t:)${${(f)~~"$(</etc/hosts)"}%%\#*}##[:blank:]#[^[:blank:]]#}}} || _etc_hosts=()
hosts=(
  "$_ssh_hosts[@]"
  "$_etc_hosts[@]"
  `hostname`
  localhost
)
zstyle ':completion:*:hosts' hosts $hosts

# I don't know what this does...
# if [[ x$WINDOW != x ]]
# then
#     SCREEN_NO="%B$WINDOW%b "
# else
#     SCREEN_NO=""
# fi

# Prompt
. $ZSH/zsh/prompt.zsh
export PROMPT='⑁ $(platform) $(directory_name) $(project_name_color)$(git_dirty)$(need_push) ❯ '

test -e "$(which direnv)" && eval "$(direnv hook zsh)"
test -e "$(which rbenv)" && eval "$(rbenv init -)"
test -e "$(which nodenv)" && eval "$(nodenv init -)"

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
# Put dirname in the iTerm window title
DISABLE_AUTO_TITLE="true"
function precmd () {
  window_title="\033]0;${PWD##*/}\007"
  echo -ne "$window_title"
}

# Aliases
alias reload='. ~/.zshrc'
alias clean-local-branches="git branch -v | grep '\[gone\]' | awk '{print \$1}' | xargs git branch -D"
# alias clean-local-branches='git branch --merged main | grep -v ''main$'' | xargs git branch -d'
# alias clean-local-branchesm='git branch --merged master | grep -v '\''master$'\'' | xargs git branch -d'
alias ...='cd ../..'
alias history='fc -l 1'
alias lsa='ls -lah'
alias l='ls -lha'
alias ll='ls -lh'
alias ga='git add --all'
alias gp='git pull --rebase --prune'
alias gpush='git push -u origin HEAD'
alias gd='git diff'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gpm='git checkout main && gp && clean-local-branches'
alias gs='git status'
alias grep='grep --color=auto'
alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

_handoff() {
  echo "Handoff:"

  for r in $@; do
    gh pr list --repo $r --author "@me" --state "merged" --search "merged:>=$(date "+%Y-%m-%d")" --json title,url,state | jq -r '.[] | "- :merged: " + .title + ": " + .url'
    gh pr list --repo $r --author "@me" --state "open" --json title,url,state | jq -r '.[] | "- :review: " + .title + ": " + .url'
  done
}
alias handoff='_handoff github/blackbird github/blackbird-mw github/copilot-api github/github'

# Go env settings (GitHub specific)
export GOPROXY=https://goproxy.githubapp.com/mod,https://proxy.golang.org/,direct
export GOPRIVATE=
export GONOPROXY=
export GONOSUMDB=github.com/github/*

# Rust: helpful defaults
export RUST_LOG=info
export RUST_BACKTRACE=1
