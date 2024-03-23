# Set global color styles, for example:
#
# function edin_error
#   set_color -o red
# end
#
# function edin_normal
#   set_color normal
#

function fish_greeting
  # cleanup fish_greeting
end

# Append a new line to every command result
function postexec_newline --on-event fish_postexec
   echo # add newline after command outputs
end
