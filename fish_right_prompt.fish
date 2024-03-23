function fish_right_prompt

  # Last command status
  set -l code $status

  # https://github.com/fish-shell/fish-shell/issues/3476#issuecomment-256058730
  # Save the cursor position, move it up one line, and move it to the right two spaces
  tput sc; tput cuu1; tput cuf 2

  if test $code != 0
    echo -ns (set_color red) '-' $code '- '
  end

  set_color $fish_color_autosuggestion 2> /dev/null; or set_color 555
  
  # Output the duration of the last command
  if test $CMD_DURATION -ne 0
    if test $CMD_DURATION -ge 60000
      set -l duration_minutes (math "floor($CMD_DURATION / 60000)")
      set -l duration_seconds (math "round(($CMD_DURATION % 60000) / 1000)")
      printf "%02d:%02d " $duration_minutes $duration_seconds
    else if test $CMD_DURATION -ge 1000
      set -l duration_seconds (math "round($CMD_DURATION / 1000)")
      echo "$duration_seconds""s "
    else
      echo "$CMD_DURATION""ms "
    end
  end

  # Output the current time
  echo (date "+%H:%M:%S")

  # Restores the cursor position
  tput rc

end
