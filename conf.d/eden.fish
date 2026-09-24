function __eden_capture_command_result --on-event fish_postexec
  set -g __eden_last_status $status
  set -g __eden_last_duration $CMD_DURATION
  set -g __eden_last_finished_at (date '+%H:%M:%S')
  set -g __eden_result_pending 1
end

function __eden_prepare_prompt --on-event fish_prompt
  # A prompt redraw keeps the result; a new prompt without a command clears it.
  if set -q __eden_result_pending
    set -g __eden_show_result 1
    set -e __eden_result_pending
  else
    set -e __eden_show_result
  end
end
