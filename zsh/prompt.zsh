autoload colors && colors
# cheers, @ehrenmurdick
# http://github.com/ehrenmurdick/config/blob/master/zsh/prompt.zsh

git_branch() {
  echo $(git symbolic-ref HEAD 2>/dev/null | awk -F/ {'print $NF'})
}

git_dirty() {
  st=$(git status 2>/dev/null | tail -n 1)
  if [[ $st == "" ]]
  then
    echo ""
  else
    if [[ $st == "nothing to commit (working directory clean)" ]]
    then
      echo "on %{$fg_bold[green]%}$(git_prompt_info)%{$reset_color%}"
    else
      echo "on %{$fg_bold[red]%}$(git_prompt_info)%{$reset_color%}"
    fi
  fi
}

git_prompt_info () {
  ref=$(git symbolic-ref HEAD 2>/dev/null) || return
# echo "(%{\e[0;33m%}${ref#refs/heads/}%{\e[0m%})"
  echo "${ref#refs/heads/}"
}

project_name () {
  name=$(pwd | awk -F'GitHub/' '{print $2}' | awk -F/ '{print $1}')
  echo $name
}

project_name_color () {
#  name=$(project_name)
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
    echo " with %{$fg_bold[magenta]%}unpushed%{$reset_color%}"
  fi
}

ruby_prompt(){
  rv=$(rbenv version-name)
  if (echo $rv &> /dev/null)
  then
    echo "%{$fg_bold[yellow]%}ruby $rv%{$reset_color%}"
  elif $(which rvm &> /dev/null)
  then
    echo "%{$fg_bold[yellow]%}$(rvm tools identifier)%{$reset_color%}"
  else
    echo ""
  fi
}

directory_name(){
  echo "%{$fg_bold[cyan]%}%1/%\/%{$reset_color%}"
}

date_time='%D{%m.%d.%Y} %@'

export PROMPT=$'$(ruby_prompt) in $(directory_name) $(project_name_color)$(git_dirty)$(need_push)\n%% '
#export RPROMPT=$'$date_time'
export RPROMPT=""

