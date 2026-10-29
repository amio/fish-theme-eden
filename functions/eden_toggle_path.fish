function eden_toggle_path -d "Toggle short path."
  if test "$theme_short_path" = 'yes'
    set -U theme_short_path no
  else
    set -U theme_short_path yes
  end
  return 0
end
