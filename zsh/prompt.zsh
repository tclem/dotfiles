autoload colors && colors
# cheers, @ehrenmurdick
# http://github.com/ehrenmurdick/config/blob/master/zsh/prompt.zsh

git_branch() {
  # echo $(git symbolic-ref HEAD 2>/dev/null | awk -F/ {'print $NF'})
  echo $(git symbolic-ref HEAD 2>/dev/null | sed -E 's/refs\/(heads|tags)\///')
}

git_dirty() {
  if [[ $(git remote get-url origin 2>/dev/null) == "git@github.com:github/github" ]]; then
    st=$(git status --no-ahead-behind 2>/dev/null | tail -n 1)
  else
    st=$(git status 2>/dev/null | tail -n 1)
  fi

  if [[ $st =~ 'fatal: not a git repository' ]]; then
    echo ""
  else
    if [[ $st =~ 'nothing to commit' ]]; then
      echo "on %{$fg[green]%}$(git_prompt_info)%{$reset_color%}"
    else
      echo "on %{$fg[red]%}$(git_prompt_info)%{$reset_color%}"
    fi
  fi
}

git_prompt_info() {
  ref=$(git symbolic-ref HEAD 2>/dev/null) || return
  echo "${ref#refs/heads/}"
}

project_name() {
  name=$(pwd | awk -F'GitHub/' '{print $2}' | awk -F/ '{print $1}')
  echo $name
}

project_name_color() {
  echo "%{\e[0;35m%}${name}%{\e[0m%}"
}

unpushed() {
  git cherry -v origin/$(git_branch) 2>/dev/null
}

need_push() {
  if [[ $PWD == "$HOME/github/github" ]]; then
    echo ""
  else
    if [[ $(unpushed) == "" ]]; then
      echo ""
    else
      echo " with %{$fg[magenta]%}unpushed%{$reset_color%}"
    fi
  fi
}

ruby_prompt() {
  rv=$(rbenv version-name)
  if (echo $rv &>/dev/null); then
    echo "%{$fg[yellow]%}ruby $rv%{$reset_color%}"
  elif $(which rvm &>/dev/null); then
    echo "%{$fg[yellow]%}$(rvm tools identifier)%{$reset_color%}"
  else
    echo ""
  fi
}

function check_last_exit_code() {
  local LAST_EXIT_CODE=$?
  if [[ $LAST_EXIT_CODE -ne 0 ]]; then
    local EXIT_CODE_PROMPT=' '
    EXIT_CODE_PROMPT+="%{$fg[red]%}-%{$reset_color%}"
    EXIT_CODE_PROMPT+="%{$fg_bold[red]%}$LAST_EXIT_CODE%{$reset_color%}"
    EXIT_CODE_PROMPT+="%{$fg[red]%}-%{$reset_color%}"
    echo "$EXIT_CODE_PROMPT"
  fi
}

directory_name() {
  echo "%{$fg[cyan]%}%1/%\/%{$reset_color%}"
}

date_time='%D{%m.%d.%Y} %@'

if [[ "$(uname -s)" == "Darwin" ]]; then
  platform="%{$fg[purple]%}$(scutil --get ComputerName)%{$reset_color%}"
else
  platform="[$(uname -s)]"
fi

export PROMPT=$'⑁ $platform $(directory_name) $(project_name_color)$(git_dirty)$(need_push) ❯ '
# export PROMPT=$'$(ruby_prompt) ⑁ $(directory_name) $(project_name_color)$(git_dirty)$(need_push) ❯ '
# export RPROMPT=""
RPROMPT='$(check_last_exit_code)'
