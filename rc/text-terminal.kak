provide-module -override text-terminal %{
  declare-option -docstring 'Extra args to `script`, e.g. `-c bash`' str text_terminal_script_args
  declare-option -hidden str text_terminal_fifos
  declare-option -docstring 'Prompt string that will be searched for. Everything after is the prompt that gets sent as a command, when typing into the buffer and hitting <s-ret>.' regex text_terminal_prompt_matcher ' \$ '

  remove-hooks global text-terminal-filetypes
  remove-hooks global text-terminal-default-keybinds

  define-command -hidden -override -docstring 'Send current prompt to the terminal' send-prompt-to-pty %{
    evaluate-commands -draft -save-regs '"/' %{
      # Match the prompt.
      set-register / %opt(text_terminal_prompt_matcher)
      # Get prompt -> select everything after it.
      execute-keys -save-regs '' "ge<a-/><ret>/.*<ret>_d"

      # Send to input fifo.
      send-to-pty %reg(dquote)
    }
    execute-keys ge
  }

  define-command send-to-pty -override -params 1 -docstring 'Send to the terminal. E.g. `send-to-pty "exit"' %{
    echo -end-of-line -to-file "%opt(text_terminal_fifos)/in" %arg(@)
  }

  define-command -override start-pty %{
    set-option current text_terminal_fifos %sh{
      fifo_dir="$(mktemp -d "${TMPDIR:-/tmp}/kak-text-terminal.XXXXXX")"
      mkfifo "$fifo_dir/in"
      printf "%s" "$fifo_dir"
    }
    fifo -scroll -name "*shell*" -script %exp{
      # TERM=vt-100 matches kak-ansi capabilities?
      tail -f %opt(text_terminal_fifos)/in | TERM=vt-100 script %opt(text_terminal_script_args) -qf /dev/null &
      pid=$!
      echo $pid > %opt(text_terminal_fifos)/pid
      wait
    }
    try ansi-enable
    set-option buffer text_terminal_fifos %opt(text_terminal_fifos)

    hook -always -once buffer BufClose .* kill-pty
    hook -always -once buffer BufCloseFifo .* kill-pty
  }

  define-command -docstring 'Kills the repl process' -hidden -override kill-pty %{ nop %sh{
    if [ -d "$kak_opt_text_terminal_fifos" ]; then
      kill "$(cat "$kak_opt_text_terminal_fifos/pid")"
      rm -rf "$kak_opt_text_terminal_fifos"
    fi
  }}

  hook -group text-terminal-default-keybinds global BufCreate ^\*shell\*$ %{
    map buffer insert <s-ret> '<esc>: send-prompt-to-pty<ret>'
    map buffer normal <s-ret> ': send-to-pty "%val(selection)"<ret>'
  }

  hook -group text-terminal-filetypes global BufSetOption filetype=(clojure|haskell) %{
    try %{
      require-module "text-terminal-%val(hook_param_capture_1)"
    }
  }
}
