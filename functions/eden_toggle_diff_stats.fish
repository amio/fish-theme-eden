function eden_toggle_diff_stats -d "Toggle Git diff statistics display."
  if test "$THEME_EDEN_HIDE_DIFF_STATS" = 'yes'
    set -U THEME_EDEN_HIDE_DIFF_STATS no
  else
    set -U THEME_EDEN_HIDE_DIFF_STATS yes
  end
  return 0
end
