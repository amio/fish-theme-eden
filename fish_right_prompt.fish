function fish_right_prompt

  # Last command status
  set -l code $status
  if test $code != 0
    echo -s (set_color red) '-' $code '- '
  end

  # Timestamp
  set_color $fish_color_autosuggestion 2> /dev/null; or set_color 555
  echo (date "+%H:%M:%S")

end
