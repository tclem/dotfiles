alias dotmate='mate $ZSH'
alias dotcd='cd $ZSH'
alias reload!='. ~/.zshrc'
alias clean-local-branches='git branch --merged main | grep -v ''main$'' | xargs git branch -d'
alias clean-local-branchesm='git branch --merged master | grep -v '\''master$'\'' | xargs git branch -d'
alias mxk="tmux kill-session -t"
alias pu='pushd'
alias po='popd'
alias ...='cd ../..'
# alias -- -='cd -'
alias history='fc -l 1'
alias lsa='ls -lah'
alias l='ls -lha'
alias ll='ls -lh'
alias tags='ctags --extra=+f -R .'
alias fix-camera='sudo killall VDCAssistant'
alias no-sleep='sudo pmset -b sleep 0; sudo pmset -b disablesleep 1' # don't sleep with lid closed
alias sleep-again='sudo pmset -b sleep 5; sudo pmset -b disablesleep 0'

# Git
alias ga='git add --all'
alias g='git'
alias gp='git pull --rebase --prune'
alias gpush='git push -u origin HEAD'
alias gd='git diff'
alias gc='git commit'
alias gitc='git commit -m'
alias gco='git checkout'
alias gb='git branch'
alias gss='git status -sb'
alias gs='git status'

# Ruby & Rails
alias be="bundle exec"
alias sc='script/console'
alias ss='script/server'
alias st='script/test'
alias t='bin/rails test'
alias migrate='rake db:migrate db:test:prepare'
alias s="ps aux | grep \"[r]uby\" | grep script/server || echo \"You're not running any, dawg.\""
alias killnginx="ps aux | grep nginx | awk '{print $2}' | xargs sudo kill -9"
alias lint='git status -s | cut -d" " -f3 | xargs rubocop -a'
