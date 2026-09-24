function _git_branch_name
  command git symbolic-ref --quiet --short HEAD 2> /dev/null
end

function _is_git_dirty
  command git status --short --ignore-submodules=dirty 2> /dev/null | string length --quiet
end

## Function to show a segment
function _prompt_segment -d "Function to show a segment"
  # Get colors
  set -l bg $argv[1]
  set -l fg $argv[2]

  # Set 'em
  set_color -b $bg
  set_color $fg

  # Print text
  if [ -n "$argv[3]" ]
    echo -n -s $argv[3]
  end

  # Reset
  set_color -b normal
  set_color normal

  # Print padding
  if [ (count $argv) = 4 ]
    echo -n -s $argv[4]
  end
end

function show_ssh_status -d "Function to show the ssh tag"
  if test "$THEME_EDEN_HIDE_SSH_TAG" != 'yes'
    if [ -n "$SSH_CLIENT" ]
      if [ (id -u) = "0" ]
        _prompt_segment red white "-SSH-" ' '
      else
        _prompt_segment blue white "-SSH-" ' '
      end
    end
  end
end

function show_host -d "Show host & user name"
  # Display [user & host] info
  if test "$THEME_EDEN_SHOW_HOST" = 'yes'
    if [ (id -u) = "0" ]
      echo -n (set_color red)
    else
      echo -n (set_color blue)
    end
    echo -n ''(hostname|cut -d . -f 1)ˇ$USER' ' (set_color normal)
  end
end

function show_cwd -d "Function to show the current working directory"
  set -l display_pwd (prompt_pwd)
  if test "$theme_short_path" != 'yes' -a "$display_pwd" != '~' -a "$display_pwd" != '/'
    set -l cwd (dirname "$display_pwd")
    test "$cwd" != '/'; and set cwd $cwd'/'
    _prompt_segment normal cyan $cwd
  end
  set_color -o cyan
  echo -n (basename "$display_pwd")' '
  set_color normal
end

function show_git_info -d "Show git branch and dirty state"
  set -l branch (_git_branch_name)
  if test -n "$branch"
    set -l git_branch "[$branch]"

    set_color -o
    if _is_git_dirty
      set_color -o red
      echo -ne "$git_branch× "
    else
      set_color -o green
      echo -ne "$git_branch "
    end
    set_color normal
  end
end

function show_prompt_char -d "Terminate with a nice prompt char"
  set -l prompt_char '»'
  if set -q THEME_EDEN_PROMPT_CHAR[1]
    set prompt_char $THEME_EDEN_PROMPT_CHAR
  end
  printf '%s ' "$prompt_char"
end

function fish_prompt
  show_ssh_status
  show_host
  show_cwd
  show_git_info
  show_prompt_char
end
