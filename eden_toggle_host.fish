function eden_toggle_host
  if test "$THEME_EDEN_SHOW_HOST" = 'yes'
    set -U THEME_EDEN_SHOW_HOST no
  else
    set -U THEME_EDEN_SHOW_HOST yes
  end
end
