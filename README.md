# text-file-terminal

An experiment at a terminal controlled from a text editor. Kinda like shell mode/eshell from emacs. Because I cannot stand scrolling up/down/selecting text/etc. in a regular terminal.

[Screen recording; demo](https://github.com/user-attachments/assets/9485ec7d-14e4-440c-a0e4-a378c3af02ce)

^No dice on the nmtui, plus the color theme used is bad.

# Usage

Load up the rc dir, then require the module. You should install [kak-ansi](https://github.com/eraserhd/kak-ansi) if you want syntax highlighting, otherwise you'll see ANSI escape characters all over.

```kakscript
hook -once global KakBegin .* %{
  require-module text-terminal
  # Regex to match the end of your $PS1, this is the default value.
  set-option global text_terminal_prompt_matcher ' \$ '
}

start-pty
# Or hit <s-ret> to send whatever is after the matched prompt.

# Manually send keys.
send-to-pty 'keys'
```

## Missing features / bugs

- No bash history.
- No LSP in scratch buffers (so no autocomplete from bash-lsp) (restriction on kak-lsp side).
- No bash autocomplete.
- No handling of ctrl-c or similar.
- Zombie processes (the terminal doesn't close :feelsbadman:). It's a bug.
- Would need some way to "inherit"/interact with the terminal so TUIs can be controlled / sudo password input.
  - Can send input, e.g. sudo password, manually via `:send-to-pty "<keys>"<ret>`. However, inserting raw character seems to not work in the prompt.

### Alternative art

- [ht](https://github.com/andyk/ht)
- [oil shell headless](https://www.oilshell.org/blog/2023/12/screencasts.html#headless-protocol-oils-web_shell)
- Python's PTY module
