function eden_toggle_host -d "Toggle [host & user] info."
  if test "$THEME_EDEN_SHOW_HOST" = 'yes'
    set -e THEME_EDEN_SHOW_HOST
  else
    set -U THEME_EDEN_SHOW_HOST yes
  end
  return 0
end
