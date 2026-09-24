set -l root (realpath (dirname (status filename))/..)
source $root/functions/fish_prompt.fish
source $root/functions/fish_right_prompt.fish
source $root/functions/fish_mode_prompt.fish
source $root/conf.d/eden.fish

function assert_contains -a output expected label
  if not string match --quiet "*$expected*" -- "$output"
    printf '%s: expected %s in %s\n' "$label" "$expected" (string escape -- "$output") >&2
    exit 1
  end
end

set -l initial_prompt (fish_prompt | string collect -N)
if string match --quiet --regex '\n' -- "$initial_prompt"
  echo 'initial prompt included a command result' >&2
  exit 1
end

set -g COLUMNS 80
set -g CMD_DURATION 119999
false
__eden_capture_command_result
if test "$__eden_last_status" -ne 1
  echo 'postexec did not capture the failed command status' >&2
  exit 1
end
__eden_prepare_prompt

set -l result_line (__eden_result_line)
assert_contains "$result_line" '-1- 02:00 ' 'failed command result'
if not string match --quiet --regex '[0-9]{2}:[0-9]{2}:[0-9]{2}$' -- "$result_line"
  echo 'command result is missing its completion time' >&2
  exit 1
end
if test (string length --visible -- "$result_line") -ne 79
  echo 'command result is not aligned to the right' >&2
  exit 1
end

set -l rendered_prompt (fish_prompt | string collect -N)
set -l prompt_lines (string split \n -- "$rendered_prompt")
if test (count $prompt_lines) -ne 2
  echo 'command result was not above the next prompt' >&2
  exit 1
end
assert_contains "$prompt_lines[1]" '-1- 02:00 ' 'result above prompt'

set -l redrawn_prompt (fish_prompt | string collect -N)
if not string match --quiet '*-1- 02:00 *' -- "$redrawn_prompt"
  echo 'prompt redraw lost the command result' >&2
  exit 1
end

__eden_prepare_prompt
set -l empty_prompt (fish_prompt | string collect -N)
if string match --quiet --regex '\n' -- "$empty_prompt"
  echo 'empty prompt repeated the previous command result' >&2
  exit 1
end

set -l right_prompt (fish_right_prompt)
if test -n "$right_prompt"
  echo 'right prompt still shows the previous command result' >&2
  exit 1
end

set -g __eden_last_duration 59999
set -l boundary (__eden_result_line)
assert_contains "$boundary" '01:00 ' 'seconds rollover'

set -g __eden_last_duration 1500
set -l seconds (__eden_result_line)
assert_contains "$seconds" '2s ' 'rounded seconds'

set -g __eden_last_duration ''
set -l zero (__eden_result_line 2>&1)
assert_contains "$zero" '0ms ' 'missing duration'
if string match --quiet '*Missing argument*' -- "$zero"
  echo 'unset duration caused an error' >&2
  exit 1
end

set -g COLUMNS 12
set -l narrow (__eden_result_line)
if test (string length --visible -- "$narrow") -gt 11
  echo 'command result wrapped in a narrow terminal' >&2
  exit 1
end

if string match --quiet --regex '\r|\x1b\[[0-9;]*[A-H]' -- "$result_line"
  echo 'command result moved the terminal cursor' >&2
  exit 1
end

set -g fish_key_bindings fish_vi_key_bindings
set -g fish_bind_mode default
set -l normal_mode (fish_mode_prompt | string collect -N)
assert_contains "$normal_mode" '🅽 ' 'vi normal mode'

set -g fish_bind_mode replace_one
set -l replace_one_mode (fish_mode_prompt | string collect -N)
assert_contains "$replace_one_mode" '🆁 ' 'vi replace-one mode'

set -g fish_bind_mode replace
set -l replace_mode (fish_mode_prompt | string collect -N)
assert_contains "$replace_mode" '🆁 ' 'vi replace mode'

if string match --quiet --regex '\n' -- "$normal_mode$replace_one_mode$replace_mode"
  echo 'vi mode prompt contains a newline' >&2
  exit 1
end

set -g fish_bind_mode insert
set -l insert_mode (fish_mode_prompt | string collect -N)
if test -n "$insert_mode"
  echo 'vi insert mode added prompt text' >&2
  exit 1
end

set -l temp_repo (mktemp -d)
command git init --quiet $temp_repo
or exit 1
set -l previous_directory $PWD
cd $temp_repo
or exit 1

if _is_git_dirty
  echo 'new repository was marked dirty' >&2
  exit 1
end

touch untracked
if not _is_git_dirty
  echo 'untracked file was not marked dirty' >&2
  exit 1
end

mkdir -p $temp_repo/eden-parent/eden-child
cd $temp_repo/eden-parent/eden-child
or exit 1
set -g theme_short_path no
set -l default_path (show_cwd | string replace --all --regex '\x1b\[[0-9;]*m' '')
assert_contains "$default_path" 'eden-parent/eden-child ' 'default path'

set -g theme_short_path yes
set -l short_path (show_cwd | string replace --all --regex '\x1b\[[0-9;]*m' '')
assert_contains "$short_path" 'eden-child ' 'short path'
if string match --quiet '*eden-parent*' -- "$short_path"
  echo 'short path included parent directory' >&2
  exit 1
end

cd $previous_directory
command rm -rf $temp_repo
echo 'smoke checks passed'
