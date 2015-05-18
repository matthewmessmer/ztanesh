# vim:ft=zsh ts=2 sw=2 sts=2
#
# agnoster's Theme - https://gist.github.com/3712874
# A Powerline-inspired theme for ZSH
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://gist.github.com/1595572).
#
# In addition, I recommend the
# [Solarized theme](https://github.com/altercation/solarized/) and, if you're
# using it on Mac OS X, [iTerm 2](http://www.iterm2.com/) over Terminal.app -
# it has significantly better color fidelity.
#
# # Goals
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'
PRIMARY_FG=black

# Characters
SEGMENT_SEPARATOR="\ue0b0"
PLUSMINUS="\u00b1"
BRANCH="\ue0a0"
DETACHED="\u27a6"
CROSS="\u2718"
LIGHTNING="\u26a1"
GEAR="\u2699"

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    print -n "%{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%}"
  else
    print -n "%{$bg%}%{$fg%}"
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && print -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    print -n "%{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    print -n "%{%k%}"
  fi
  print -n "%{%f%}"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  local user=`whoami`

  if [[ "$user" != "$DEFAULT_USER" || -n "$SSH_CONNECTION" ]]; then
    prompt_segment $PRIMARY_FG default " %(!.%{%F{yellow}%}.)$user@%m "
  fi
}

# Git: branch/detached head, dirty status
prompt_git() {
  local color ref
  is_dirty() {
    test -n "$(git status --porcelain --ignore-submodules)"
  }
  ref="$vcs_info_msg_0_"
  if [[ -n "$ref" ]]; then
    if is_dirty; then
      color=yellow
      ref="${ref} $PLUSMINUS"
    else
      color=green
      ref="${ref} "
    fi
    if [[ "${ref/.../}" == "$ref" ]]; then
      ref="$BRANCH $ref"
    else
      ref="$DETACHED ${ref/.../}"
    fi
    prompt_segment $color $PRIMARY_FG
    print -Pn " $ref"
  fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment blue $PRIMARY_FG ' %~ '
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local symbols
  symbols=()
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}$CROSS"
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}$LIGHTNING"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}$GEAR"

  [[ -n "$symbols" ]] && prompt_segment $PRIMARY_FG default " $symbols "
}

## Main prompt
prompt_agnoster_main() {
  RETVAL=$?
  CURRENT_BG='NONE'
  prompt_status
  prompt_context
  prompt_dir
  prompt_git
  prompt_end
}

prompt_agnoster_precmd() {
  vcs_info
  PROMPT='%{%f%b%k%}$(prompt_agnoster_main) '
}

prompt_agnoster_setup() {
  autoload -Uz add-zsh-hook
  autoload -Uz vcs_info

  prompt_opts=(cr subst percent)

  add-zsh-hook precmd prompt_agnoster_precmd

  zstyle ':vcs_info:*' enable git
  zstyle ':vcs_info:*' check-for-changes false
  zstyle ':vcs_info:git*' formats '%b'
  zstyle ':vcs_info:git*' actionformats '%b (%a)'
}

prompt_agnoster_setup "$@"

if [[ -e /etc/server-status ]]
then
    SERVER_STATUS_ENABLED=1
fi

PROMPT_HOSTNAME=`hostname`

IMAGE_NAME=""

if [[ -e /etc/issue ]] 
then
    IMAGE_NAME="`grep 'Image:' /etc/issue|sed 's/Image: *\([^ ]\+\).*/\1/'`"
fi

function setup_prompt {
    RPROMPT=`echo -ne "%{\033[A%}%B[%{\033[${PROMPT_USER_COLOR:-1;33}m%}%n%{\033[0m%}%B@%{\033[${PROMPT_HOST_COLOR:-1;33}m%}$PROMPT_HOSTNAME%b%B][%{\033[1;32m%}%T%b%B]%{\033[B%}"`
    PROMPT=`echo -ne '%B$(git_prompt_info)\n%{\033[0m%}%B[%{\033[36m%}%~%b%B]%#'`" "

    PROPOSED_VIRTUAL_ENV=$(check_unset_venv)
    proposed_envname=`basename "$PROPOSED_VIRTUAL_ENV"`

    if [[ "$SERVER_STATUS_ENABLED" == "1" ]]
    then
        SERVER_STATUS=`xargs echo -ne < /etc/server-status`
        if [[ $SERVER_STATUS == 'LIVE!' ]]
        then
            COLOR="1;5;41;33m"
        else
            COLOR="0;30;46m"
        fi
        if [[ $IMAGE_NAME != '' ]]
        then
            IMAGENAME="%B[%b$IMAGE_NAME%B]%b"
        fi
        PROMPT=`echo -ne "%{\033[1;37m%}[%{\033[$COLOR%}$SERVER_STATUS%{\033[0;37;1m%}]%{\033[0m%}$IMAGENAME"`"$PROMPT"
        unset COLOR
    fi

    if [[ "$VIRTUAL_ENV" != "" ]]
    then
        envname=`basename "$VIRTUAL_ENV"`
        
        if [[ "$PROPOSED_VIRTUAL_ENV" != "" && "$PROPOSED_VIRTUAL_ENV" != "$VIRTUAL_ENV" ]]
        then
            PROMPT=`echo -ne "%{\033[1;33m%}[%{\033[0;31;43m%}$proposed_envname%{\033[0;33;1m%}]%{\033[0m%}"`"$PROMPT"
        fi

        PROMPT=`echo -ne "%{\033[1;36m%}[%{\033[1;34m%}$envname%{\033[36m%}]%{\033[0m%}"`"$PROMPT"
    else
        if [[ "$proposed_envname" != "" ]]
        then
            PROMPT=`echo -ne "%{\033[1;31m%}[%{\033[0;30;41;5m%}$proposed_envname%{\033[0;31;1m%}]%{\033[0m%}"`"$PROMPT"
        fi
    fi
}

if [[ -x /usr/bin/hostname-filter ]]
then
    PROMPT_HOSTNAME=`/usr/bin/hostname-filter`
fi

setup_prompt


ZSH_THEME_GIT_PROMPT_PREFIX="[%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[yellow]%}✗%{$fg[white]%}]"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[white]%}]"

