function eden_toggle_path -d "Toggle short path."
  if test "$theme_short_path" = 'yes'
    set -e theme_short_path
  else
    set -g theme_short_path yes
  end
  return 0
end
