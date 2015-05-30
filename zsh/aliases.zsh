alias dotmate='mate $ZSH'
alias dotcd='cd $ZSH'
alias reload!='. ~/.zshrc'
alias clean-local-branches='git branch --merged master | grep -v '\''master$'\'' | xargs git branch -d'
alias mxk="tmux kill-session -t"
alias pu='pushd'
alias po='popd'
alias ...='cd ../..'
alias -- -='cd -'
alias history='fc -l 1'
alias lsa='ls -lah'
alias l='ls -la'
alias ll='ls -l'
alias tags='ctags --extra=+f -R .'

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
alias t='bin/testrb'
alias migrate='rake db:migrate db:test:clone'
alias s="ps aux | grep \"[r]uby\" | grep script/server || echo \"You're not running any, dawg.\""
alias killnginx="ps aux | grep nginx | awk '{print $2}' | xargs sudo kill -9"

# https://gist.github.com/b00f68b40e3ebcc1269c
function find_rake {
  if [[ -f Gemfile && -x bin/rake ]]; then
    bin/rake "$@"
  else
    rake "$@"
  fi
}

alias rake=find_rake
