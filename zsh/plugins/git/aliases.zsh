# Use `hub` as our git wrapper:
#   http://defunkt.github.com/hub/
git() {
  hub "$@"
}

ga() {
 git add .
 git add -u
}

alias g='git'
alias gp='git pull --rebase --prune'
alias gpush='git push origin HEAD'
alias gd='git diff'
alias gc='git commit'
alias gitc='git commit -m'
alias gco='git checkout'
alias gb='git branch'
alias gss='git status -sb'
alias gs='git status'
