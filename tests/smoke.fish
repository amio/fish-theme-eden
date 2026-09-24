set -l root (realpath (dirname (status filename))/..)
source $root/functions/fish_prompt.fish
source $root/functions/fish_right_prompt.fish

function assert_contains -a output expected label
  if not string match --quiet "*$expected*" -- "$output"
    printf '%s: expected %s in %s\n' "$label" "$expected" (string escape -- "$output") >&2
    exit 1
  end
end

set -l duration (begin; set -g CMD_DURATION 119999; fish_right_prompt; end)
assert_contains "$duration" '02:00 ' 'minute rollover'

set -l boundary (begin; set -g CMD_DURATION 59999; fish_right_prompt; end)
assert_contains "$boundary" '01:00 ' 'seconds rollover'

set -l seconds (begin; set -g CMD_DURATION 1500; fish_right_prompt; end)
assert_contains "$seconds" '2s ' 'rounded seconds'

set -l failed (begin; set -e CMD_DURATION; false; fish_right_prompt 2>&1; end)
assert_contains "$failed" '-1- ' 'exit status'
if string match --quiet '*Missing argument*' -- "$failed"
  echo 'unset duration caused an error' >&2
  exit 1
end

if string match --quiet --regex '\r|\x1b\[[0-9;]*[A-H]' -- "$failed"
  echo 'right prompt moved the terminal cursor' >&2
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

cd $previous_directory
command rm -rf $temp_repo
echo 'smoke checks passed'
