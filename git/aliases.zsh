# Use `hub` as our git wrapper:
#   http://defunkt.github.com/hub/
git(){hub "$@"}
ga() {
 git add .
 git add -u
}
alias g='git'
alias gp='git pull --rebase --prune'
alias gpush='git push origin HEAD'
# alias glog="git log --graph --pretty=format:'%Cred%h%Creset %an: %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"
# alias gp='git push origin HEAD'
alias gd='git diff'
alias gc='git commit'
alias gitc='git commit -m'
# alias gca='git commit -a'
alias gco='git checkout'
alias gb='git branch'
alias gss='git status -sb' # upgrade your git if -sb breaks for you. it's fun.
alias gs='git status'
# alias grm="git status | grep deleted | awk '{print \$3}' | xargs git rm"
