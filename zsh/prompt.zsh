#! /bin/zsh
#
# Functions for helping construct a nice prompt

if [[ "$(uname -s)" == "Darwin" ]]; then
  typeset -g _PROMPT_PLATFORM="$(scutil --get ComputerName 2>/dev/null || hostname -s)"
else
  typeset -g _PROMPT_PLATFORM="[$(uname -s)]"
fi

typeset -gi _PROMPT_GIT_CACHE_TTL=2
typeset -gi _PROMPT_GIT_CACHE_TS=0
typeset -gi _PROMPT_GIT_CACHE_USED=0
typeset -g _PROMPT_GIT_CACHE_KEY=""
typeset -g _PROMPT_GIT_DIRTY_SEGMENT=""
typeset -g _PROMPT_GIT_PUSH_SEGMENT=""

platform() {
  echo "$_PROMPT_PLATFORM"
}

git_prompt_info() {
  ref=$(git symbolic-ref HEAD 2>/dev/null) || return
  echo "${ref#refs/heads/}"
}

# cheers, @ehrenmurdick
# http://github.com/ehrenmurdick/config/blob/master/zsh/prompt.zsh
git_branch() {
  git symbolic-ref --quiet --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null
}

_prompt_git_clear_state() {
  _PROMPT_GIT_DIRTY_SEGMENT=""
  _PROMPT_GIT_PUSH_SEGMENT=""
  _PROMPT_GIT_CACHE_USED=0
}

_prompt_git_collect() {
  local now=${EPOCHSECONDS:-$(date +%s)}
  local git_dir branch dirty upstream counts ahead
  local -a lr_counts

  command -v git >/dev/null 2>&1 || {
    _prompt_git_clear_state
    return
  }

  git_dir=$(git rev-parse --git-dir 2>/dev/null) || {
    _prompt_git_clear_state
    return
  }

  if [[ "$git_dir:$PWD" == "$_PROMPT_GIT_CACHE_KEY" ]] \
    && (( now - _PROMPT_GIT_CACHE_TS < _PROMPT_GIT_CACHE_TTL )); then
    _PROMPT_GIT_CACHE_USED=1
    return
  fi

  _PROMPT_GIT_CACHE_USED=0
  _PROMPT_GIT_CACHE_KEY="$git_dir:$PWD"
  _PROMPT_GIT_CACHE_TS=$now

  branch=$(git_branch)
  if [[ -z "$branch" ]]; then
    _prompt_git_clear_state
    return
  fi

  dirty=0
  git diff --no-ext-diff --quiet --ignore-submodules --cached 2>/dev/null || dirty=1
  if (( dirty == 0 )); then
    git diff --no-ext-diff --quiet --ignore-submodules 2>/dev/null || dirty=1
  fi
  if (( dirty == 0 )) && [[ -n "$(git ls-files --others --exclude-standard --directory 2>/dev/null | head -n 1)" ]]; then
    dirty=1
  fi

  if (( dirty )); then
    _PROMPT_GIT_DIRTY_SEGMENT="on %F{red}${branch}%{$reset_color%}"
  else
    _PROMPT_GIT_DIRTY_SEGMENT="on %F{green}${branch}%{$reset_color%}"
  fi

  _PROMPT_GIT_PUSH_SEGMENT=""
  if [[ $PWD != "$HOME/github/github" ]]; then
    upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null)
    if [[ -n "$upstream" ]]; then
      counts=$(git rev-list --left-right --count "${upstream}...HEAD" 2>/dev/null)
      lr_counts=(${=counts})
      ahead=${lr_counts[2]:-0}
      if [[ -n "$ahead" ]] && (( ahead > 0 )); then
        _PROMPT_GIT_PUSH_SEGMENT=" with %F{magenta}unpushed%{$reset_color%}"
      fi
    fi
  fi
}

git_dirty() {
  echo "$_PROMPT_GIT_DIRTY_SEGMENT"
}

prompt_lead_char() {
  if [[ -n "$_PROMPT_GIT_DIRTY_SEGMENT" ]] && (( _PROMPT_GIT_CACHE_USED )); then
    echo "%F{yellow}⑁%{$reset_color%}"
  else
    echo "⑁"
  fi
}

project_name() {
  local name
  name=$(git rev-parse --show-toplevel 2>/dev/null)
  if [[ -n "$name" ]]; then
    name="${name##*/}"
  else
    name="${PWD##*/}"
  fi
  echo "$name"
}

project_name_color() {
  local name current_dir
  name=$(project_name)
  current_dir="${PWD##*/}"

  if [[ -z "$name" || "$name" == "$current_dir" ]]; then
    echo ""
  else
    echo "%{\e[0;35m%}${name}%{\e[0m%} "
  fi
}

unpushed() {
  git cherry -v origin/$(git_branch) 2>/dev/null
}

need_push() {
  echo "$_PROMPT_GIT_PUSH_SEGMENT"
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

check_last_exit_code() {
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
  echo "%F{cyan}%1/%\/%{$reset_color%}"
}

autoload -Uz add-zsh-hook
if (( ${precmd_functions[(I)_prompt_git_collect]:-0} == 0 )); then
  add-zsh-hook precmd _prompt_git_collect
fi
