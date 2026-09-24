function fish_right_prompt
  set -l code $status

  if test $code != 0
    printf '%s-%s- ' (set_color red) $code
  end

  set_color $fish_color_autosuggestion 2> /dev/null; or set_color 555

  if test -n "$CMD_DURATION"; and test "$CMD_DURATION" -gt 0
    if test "$CMD_DURATION" -ge 1000
      set -l total_seconds (math "round($CMD_DURATION / 1000)")
      if test "$total_seconds" -ge 60
        set -l minutes (math "floor($total_seconds / 60)")
        set -l seconds (math "$total_seconds % 60")
        printf '%02d:%02d ' $minutes $seconds
      else
        printf '%ss ' $total_seconds
      end
    else
      printf '%sms ' $CMD_DURATION
    end
  end

  printf '%s' (date '+%H:%M:%S')
  set_color normal
end
