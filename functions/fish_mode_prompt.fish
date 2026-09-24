function fish_mode_prompt --description 'Displays the current mode'
  if test "$fish_key_bindings" != fish_vi_key_bindings
    return
  end

  switch $fish_bind_mode
    case default
      set_color --bold red
      printf '🅽 '
    case insert
      return
    case replace_one replace
      set_color --bold green
      printf '🆁 '
    case visual
      set_color --bold brmagenta
      printf '🆅 '
    case '*'
      return
  end
  set_color normal
end
