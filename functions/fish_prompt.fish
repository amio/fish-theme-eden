function _git_branch_name
  command git symbolic-ref --quiet --short HEAD 2> /dev/null
  or begin
    set -l commit (command git rev-parse --short HEAD 2> /dev/null)
    if test -n "$commit"
      printf 'detached@%s\n' "$commit"
    end
  end
end

function _is_git_worktree
  # Linked worktrees have their own Git directory and share the common directory.
  set -l git_dirs (command git rev-parse --path-format=absolute --git-dir --git-common-dir 2> /dev/null)
  test (count $git_dirs) -eq 2; and test "$git_dirs[1]" != "$git_dirs[2]"
end

function _is_git_dirty
  command git status --short --ignore-submodules=dirty 2> /dev/null | string length --quiet
end

function _git_diff_stats
  set -l root (command git rev-parse --show-toplevel 2> /dev/null)
  set -l base HEAD
  if not command git rev-parse --verify HEAD > /dev/null 2>&1
    # Compare against an empty tree before the first commit.
    set base (command git hash-object -t tree /dev/null)
  end
  begin
    command git -C "$root" diff --numstat --no-ext-diff --no-textconv --ignore-submodules=dirty $base -- 2> /dev/null
    for file in (command git -C "$root" ls-files --others --exclude-standard -z | string split0)
      command git diff --no-index --numstat --no-ext-diff --no-textconv -- /dev/null "$root/$file" 2> /dev/null
    end
  end | command awk -F '\t' '$1 ~ /^[0-9]+$/ && $2 ~ /^[0-9]+$/ { added += $1; removed += $2 } END { printf "%d %d\n", added, removed }'
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
      if fish_is_root_user
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
    if fish_is_root_user
      echo -n (set_color red)
    else
      echo -n (set_color blue)
    end
    echo -n ''(prompt_hostname)ˇ$USER' ' (set_color normal)
  end
end

function show_cwd -d "Function to show the current working directory"
  set -l display_pwd (prompt_pwd --full-length-dirs 2)
  if test "$theme_short_path" != 'yes' -a "$display_pwd" != '~' -a "$display_pwd" != '/'
    set -l cwd (path dirname "$display_pwd")
    test "$cwd" != '/'; and set cwd $cwd'/'
    _prompt_segment normal cyan $cwd
  end
  set_color -o cyan
  echo -n (path basename "$display_pwd")' '
  set_color normal
end

function show_git_info -d "Show git HEAD, linked worktree, and dirty state"
  set -l branch (_git_branch_name)
  if test -n "$branch"
    set -l git_branch "[$branch]"
    if _is_git_worktree
      set git_branch "{$branch}"
    end

    set_color -o
    if _is_git_dirty
      set_color -o red
      if test "$THEME_EDEN_HIDE_DIFF_STATS" = 'yes'
        printf '%s× ' "$git_branch"
      else
        printf '%s ' "$git_branch"
        set -l stats (string split ' ' -- (_git_diff_stats))
        set_color -o green
        printf '+%s' $stats[1]
        set_color -o red
        printf '-%s ' $stats[2]
      end
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

function __eden_result_line
  set -l duration $__eden_last_duration
  if test -z "$duration"
    set duration 0
  end

  if test "$duration" -ge 1000
    set -l total_seconds (math "round($duration / 1000)")
    if test "$total_seconds" -ge 60
      set -l minutes (math "floor($total_seconds / 60)")
      set -l seconds (math "$total_seconds % 60")
      set duration (printf '%02d:%02d' $minutes $seconds)
    else
      set duration "$total_seconds"s
    end
  else
    set duration "$duration"ms
  end

  set -l summary
  set -l normal_color (set_color normal)
  if test "$__eden_last_status" -ne 0
    set -l error_color (set_color red)
    set summary "$error_color-$__eden_last_status- $normal_color"
  end

  set -l muted (set_color $fish_color_autosuggestion 2> /dev/null; or set_color 555)
  set summary "$summary$muted$duration $__eden_last_finished_at$normal_color"

  # Leave the final column free to avoid terminal auto-wrap.
  set -l width (math "$COLUMNS - 1")
  if test "$width" -lt 1
    set width 1
  end
  set summary (string shorten --left --max $width -- "$summary")
  string pad --width $width -- "$summary"
end

function fish_prompt
  if set -q __eden_show_result
    __eden_result_line
  else
    printf '\n'
  end
  show_ssh_status
  show_host
  show_cwd
  show_git_info
  show_prompt_char
end
