set -l root (realpath (dirname (status filename))/..)
source $root/functions/fish_prompt.fish
source $root/functions/fish_right_prompt.fish
source $root/functions/fish_mode_prompt.fish
source $root/functions/eden_toggle_diff_stats.fish
source $root/conf.d/eden.fish

function assert_contains -a output expected label
  if not string match --quiet "*$expected*" -- "$output"
    printf '%s: expected %s in %s\n' "$label" "$expected" (string escape -- "$output") >&2
    exit 1
  end
end

function assert_equal -a output expected label
  if test "$output" != "$expected"
    printf '%s: expected %s, got %s\n' "$label" (string escape -- "$expected") (string escape -- "$output") >&2
    exit 1
  end
end

set -l initial_prompt (fish_prompt | string collect -N)
if not string match --quiet --regex '^\n[^\n]+$' -- "$initial_prompt"
  echo 'initial prompt is missing its leading blank line or included a command result' >&2
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
if not string match --quiet --regex '^\n[^\n]+$' -- "$empty_prompt"
  echo 'empty prompt is missing its leading blank line or repeated the previous command result' >&2
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

set -l temp_root (mktemp -d)
set -l temp_repo $temp_root/main
command git init --quiet $temp_repo
or exit 1
set -l previous_directory $PWD
cd $temp_repo
or exit 1

if _is_git_dirty
  echo 'new repository was marked dirty' >&2
  exit 1
end

command git -c user.name='Eden Test' -c user.email=eden@example.invalid commit --quiet --allow-empty -m initial
or exit 1
set -l main_branch (_git_branch_name)
assert_equal (show_git_info | string replace --all --regex '\x1b\[[0-9;]*m' '') "[$main_branch] " 'main checkout label'

command git worktree add --quiet -b eden-feature $temp_root/linked
or exit 1
command git worktree add --quiet --detach $temp_root/detached
or exit 1

cd $temp_root/linked
or exit 1
assert_equal (show_git_info | string replace --all --regex '\x1b\[[0-9;]*m' '') '{eden-feature} ' 'linked worktree label'
mkdir nested
cd nested
or exit 1
assert_equal (show_git_info | string replace --all --regex '\x1b\[[0-9;]*m' '') '{eden-feature} ' 'nested worktree label'
echo changed > ../tracked
assert_equal (show_git_info | string replace --all --regex '\x1b\[[0-9;]*m' '') '{eden-feature} +0-0 u1 ' 'untracked worktree changes'
command git add ../tracked
or exit 1
assert_equal (show_git_info | string replace --all --regex '\x1b\[[0-9;]*m' '') '{eden-feature} +1-0 ' 'staged worktree changes'

eden_toggle_diff_stats
assert_equal (show_git_info | string replace --all --regex '\x1b\[[0-9;]*m' '') '{eden-feature}× ' 'hidden diff statistics'
set -l hidden_git (show_git_info | string collect -N)
set -l dirty_label (printf '%s{eden-feature}× ' (set_color -o red))
if not string match --quiet --regex (string escape --style=regex -- "$dirty_label") -- "$hidden_git"
  echo 'hiding diff statistics lost the red dirty branch marker' >&2
  exit 1
end
eden_toggle_diff_stats
assert_equal (show_git_info | string replace --all --regex '\x1b\[[0-9;]*m' '') '{eden-feature} +1-0 ' 'restored diff statistics'

cd $temp_root/detached
or exit 1
set -l commit (command git rev-parse --short HEAD)
assert_equal (show_git_info | string replace --all --regex '\x1b\[[0-9;]*m' '') "{detached@$commit} " 'detached worktree label'
touch untracked
assert_equal (show_git_info | string replace --all --regex '\x1b\[[0-9;]*m' '') "{detached@$commit} +0-0 u1 " 'detached worktree changes'

cd $temp_repo
or exit 1
command git checkout --quiet --detach
or exit 1
assert_equal (show_git_info | string replace --all --regex '\x1b\[[0-9;]*m' '') "[detached@$commit] " 'main detached HEAD label'
command git checkout --quiet $main_branch
or exit 1

cd $temp_root
or exit 1
set -l outside_git (show_git_info | string collect)
assert_equal "$outside_git" '' 'outside Git repository'
cd $temp_repo
or exit 1

touch untracked
if not _is_git_dirty
  echo 'untracked file was not marked dirty' >&2
  exit 1
end

printf 'one\ntwo\nthree\n' > tracked
command git add tracked
command git -c user.name='Eden Test' -c user.email=eden@example.invalid commit --quiet -m tracked
or exit 1
printf 'one\nstaged\nthree\n' > tracked
command git add tracked
printf 'one\nworking\nthree\n' > tracked
assert_equal (_git_diff_stats) '1 1' 'net staged and unstaged diff'
set -l colored_git (show_git_info | string collect -N)
set -l expected_colors (printf '%s+1%s-1 ' (set_color -o green) (set_color -o red))
if not string match --quiet --regex (string escape --style=regex -- "$expected_colors") -- "$colored_git"
  echo 'diff statistics did not use green additions and red deletions' >&2
  exit 1
end

printf 'new\nlines\n' > 'untracked with spaces'
printf 'ignored\n' > ignored
printf 'ignored\n' > .git/info/exclude
printf '\0binary\n' > binary
assert_equal (_git_diff_stats) '1 1' 'untracked contents do not contribute to line statistics'
mkdir nested
cd nested
or exit 1
command git config diff.relative true
assert_equal (_git_diff_stats) '1 1' 'repository-wide diff from a subdirectory'
cd $temp_repo
or exit 1
printf 'one\ntwo\nthree\n' > tracked
assert_equal (_git_diff_stats) '0 0' 'staged and unstaged changes cancel out'
command rm tracked
assert_equal (_git_diff_stats) '0 3' 'deleted tracked file'

command git init --quiet $temp_root/unborn
or exit 1
cd $temp_root/unborn
or exit 1
printf 'one\ntwo\n' > tracked
command git add tracked
printf 'one\n' > tracked
printf 'new\n' > untracked
assert_equal (_git_diff_stats) '1 0' 'net diff before first commit'

command git init --quiet $temp_root/diff-options
or exit 1
cd $temp_root/diff-options
or exit 1
command git config diff.algorithm histogram
command git config diff.renames false
printf '%s\n' b c a f d d b a a a d e c a b > algorithm
seq 40 > original
command git add .
command git -c user.name='Eden Test' -c user.email=eden@example.invalid commit --quiet -m initial
or exit 1
printf '%s\n' e e c c b a c b a f c c b b c > algorithm
assert_equal (_git_diff_stats) '9 9' 'Tig default algorithm despite diff.algorithm configuration'
command git restore algorithm
command cp original copied
printf 'changed\n' >> original
printf '%s\n' (seq 39) replacement > copied
command git add original copied
assert_equal (_git_diff_stats) '2 1' 'Tig copy detection despite diff.renames configuration'
command git reset --quiet --hard HEAD
or exit 1

# Untracked contents must not run clean filters while drawing the prompt.
command git config filter.eden-probe.clean 'printf invoked >> .git/eden-filter-invocations; cat'
printf 'untracked-* filter=eden-probe\n' > .gitattributes
for number in (seq 16)
  printf 'one\ntwo\n' > untracked-$number
end
set -l tab_name (printf 'tab\tname')
set -l newline_name (printf 'line\nbreak' | string collect)
touch "$tab_name" "$newline_name"
printf 'ignored\n' > ignored
printf 'ignored\n' >> .git/info/exclude
assert_equal (_git_diff_stats) '0 0' 'untracked files have no line statistics'
assert_equal (_git_untracked_count) '19' 'untracked file count handles special filenames and ignores excluded files'
assert_contains (show_git_info | string replace --all --regex '\x1b\[[0-9;]*m' '') '+0-0 u19 ' 'untracked file count in prompt'
if test -e .git/eden-filter-invocations
  echo 'prompt read untracked contents through a clean filter' >&2
  exit 1
end
mkdir nested
cd nested
or exit 1
assert_equal (_git_untracked_count) '19' 'repository-wide untracked count from a subdirectory'
cd ..
or exit 1
command git add untracked-1
or exit 1
if not test -e .git/eden-filter-invocations
  echo 'clean filter fixture did not run when the new file was staged' >&2
  exit 1
end
assert_equal (_git_diff_stats) '2 0' 'new files contribute line statistics after staging'
assert_equal (_git_untracked_count) '18' 'staged new files leave the untracked count'

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
command rm -rf $temp_root
echo 'smoke checks passed'
