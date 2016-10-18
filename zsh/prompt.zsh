autoload colors && colors
# cheers, @ehrenmurdick
# http://github.com/ehrenmurdick/config/blob/master/zsh/prompt.zsh

git_branch() {
  echo $(git symbolic-ref HEAD 2>/dev/null | awk -F/ {'print $NF'})
}

git_dirty() {
  # if [[ $st == "" ]]
  st=$(git status 2>/dev/null | tail -n 1)
  if [[ $st =~ 'fatal: Not a git repository' ]]
  then
    echo ""
  else
    if [[ $st =~ 'nothing to commit' ]]
    then
      echo "on %{$fg[green]%}$(git_prompt_info)%{$reset_color%}"
    else
      echo "on %{$fg[red]%}$(git_prompt_info)%{$reset_color%}"
    fi
  fi
}

git_prompt_info () {
  ref=$(git symbolic-ref HEAD 2>/dev/null) || return
  echo "${ref#refs/heads/}"
}

project_name () {
  name=$(pwd | awk -F'GitHub/' '{print $2}' | awk -F/ '{print $1}')
  echo $name
}

project_name_color () {
  echo "%{\e[0;35m%}${name}%{\e[0m%}"
}

unpushed () {
  git cherry -v origin/$(git_branch) 2>/dev/null
}

need_push () {
  if [[ $(unpushed) == "" ]]
  then
    echo ""
  else
    echo " with %{$fg[magenta]%}unpushed%{$reset_color%}"
  fi
}

ruby_prompt(){
  rv=$(rbenv version-name)
  if (echo $rv &> /dev/null)
  then
    echo "%{$fg[yellow]%}ruby $rv%{$reset_color%}"
  elif $(which rvm &> /dev/null)
  then
    echo "%{$fg[yellow]%}$(rvm tools identifier)%{$reset_color%}"
  else
    echo ""
  fi
}

directory_name(){
  echo "%{$fg[cyan]%}%1/%\/%{$reset_color%}"
}

date_time='%D{%m.%d.%Y} %@'

export PROMPT=$'⑁ $(directory_name) $(project_name_color)$(git_dirty)$(need_push) ❯ '
# export PROMPT=$'$(ruby_prompt) ⑁ $(directory_name) $(project_name_color)$(git_dirty)$(need_push) ❯ '
# export RPROMPT=""
