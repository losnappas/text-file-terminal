# text-file-terminal

[Screen recording; demo](https://github.com/user-attachments/assets/6f5c741a-5199-4045-9a1b-b3a782d8663d)

Create a headless terminal and control it via a FIFO. Only tested on linux, might work on *nix.

Integration for kakoune editor is provided in `rc/text-file-terminal.kak`.

## Usage

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
