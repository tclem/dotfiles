alias dotmate='mate $ZSH'
alias dotcd='cd $ZSH'

alias reload!='. ~/.zshrc'
alias v=mvim
alias emacs="/usr/local/Cellar/emacs/23.3a/Emacs.app/Contents/MacOS/Emacs -nw"
alias e="subl -n ."

# mvim()
# {
  # (unset GEM_PATH GEM_HOME; command mvim "$@")
# }

alias pu='pushd'
alias po='popd'
alias ...='cd ../..'
alias -- -='cd -'
alias history='fc -l 1'

alias lsa='ls -lah'
alias l='ls -la'
alias ll='ls -l'

# https://gist.github.com/b00f68b40e3ebcc1269c
function find_rake {
  if [[ -f Gemfile && -x bin/rake ]]; then
    bin/rake "$@"
  else
    rake "$@"
  fi
}

alias rake=find_rake
