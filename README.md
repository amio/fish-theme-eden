# Eden

A theme for [Fish](https://fishshell.com) with Git status, command duration, and a compact right prompt.

## Install

With [Oh My Fish](https://github.com/oh-my-fish/oh-my-fish):

```fish
omf install eden
```

Remove it with `omf remove eden`.

With [Fisher](https://github.com/jorgebucaran/fisher):

```fish
fisher install amio/fish-theme-eden
```

Remove it with `fisher remove amio/fish-theme-eden`.

## Features

- The right prompt shows the current time, last command duration, and nonzero exit status.
- The left prompt shows the current directory and Git branch, with a marker for uncommitted changes.
- `eden_toggle_path` switches between abbreviated and short directory paths.
- `eden_toggle_host` shows or hides the host and user.
- `eden_prompt_char` sets a custom prompt character; run it without an argument to restore `»`.
- `eden_toggle_ssh_tag` shows or hides the `-SSH-` tag on SSH connections. The tag is red for root and blue otherwise.

## Development

Run `fish --no-config tests/smoke.fish` to check prompt formatting and Git status detection.

## License

[MIT](LICENSE) © [Amio](https://github.com/amio)
