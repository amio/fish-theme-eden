function eden_toggle_ssh_tag -d "Toggle -SSH- tag display."
  if test "$THEME_EDEN_HIDE_SSH_TAG" = 'yes'
    set -U THEME_EDEN_HIDE_SSH_TAG no
  else
    set -U THEME_EDEN_HIDE_SSH_TAG yes
  end
  return 0
end
