# text-file-terminal

An experiment at a terminal controlled from a text editor. Kinda like shell mode/eshell from emacs. Because I cannot stand scrolling up/down/selecting text/etc. in a regular terminal.

[Screen recording; demo](https://github.com/user-attachments/assets/6f5c741a-5199-4045-9a1b-b3a782d8663d)

Create a headless terminal and control it via a FIFO. Only tested on linux, might work on *nix.

# Usage

```console
$ text-file-terminal --help
usage: text-file-terminal [-h] [--commands-fifo FIFO_PATH]
                          [--sh-binary SH_BINARY] [--rows ROWS] [--cols COLS]

options:
  -h, --help            show this help message and exit
  --commands-fifo FIFO_PATH
                        FIFO where the program should expect input from. The
                        fifo is expected to exists already. (default:
                        /tmp/terminal_control)
  --sh-binary SH_BINARY
                        Which shell binary to launch. (default: bash)
  --rows ROWS           Terminal height from e.g. `tput lines`. (default: 100)
  --cols COLS           Terminal width from e.g. `tput cols`. (default: 100)
$ fifo="/tmp/terminal.fifo"
$ mkfifo "$fifo"
$ text-file-terminal --commands-fifo "$fifo" # This forks immediately (consider it a bug, however)
$ echo ls > $fifo # Output on stdout with ansi escapes.
flake.lock [1;4;33mflake.nix[0m [1;4;33mpyproject.toml[0m [1;34mrc[0m [1;4;33mREADME.md[0m [1;34msrc[0m UNLICENSE
$ echo 'A=123' > "$fifo"
$ echo 'echo $A' > "$fifo"
123
```

For text editor integration, you need to be able to render ansi escape codes into something meaningful.

## Missing features / bugs

- No bash history.
- No LSP in scratch buffers (so no autocomplete from bash-lsp) (restriction on kak-lsp side).
- No bash autocomplete.
- No handling of ctrl-c.
- Zombie processes (the immediate fork problem); as text editor quits the forked/setsid terminal process hangs around. It should go away.
- Need some way to "inherit" the terminal so TUIs can be controlled / sudo password input.
- Would be neat to have a more straightforward system for the text input, current doesn't play too nice with windowing and seems burdensome on the user.
- No straightforward interop path, e.g. adding commands like "pick file" to insert to prompt.

### Alternative art

- [ht](https://github.com/andyk/ht)
- [oil shell headless](https://www.oilshell.org/blog/2023/12/screencasts.html#headless-protocol-oils-web_shell)
