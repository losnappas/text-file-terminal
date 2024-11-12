provide-module -override text-terminal %{
  declare-option -hidden int text_terminal_counter 0
  declare-option -docstring 'Path to `script(1)` program' str text_terminal_script_exec 'script'
  declare-option -hidden str text_terminal_fifos
  declare-option -docstring 'Prompt string that will be searched for' regex text_terminal_prompt_matcher ' \$ '

  define-command -hidden -override -docstring 'Send current prompt to the terminal' send-prompt-to-pty %{
    evaluate-commands -draft -save-regs '"' %{
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
      fifo_dir="$(mktemp -d "${TMP:-/tmp}/kak-text-terminal.XXXXXX")"
      mkfifo "$fifo_dir/in"
      printf "%s" "$fifo_dir"
    }
    fifo -scroll -name "*shell-%opt(text_terminal_counter)*" -script %exp{
      tail -f %opt(text_terminal_fifos)/in | script -qf /dev/null &
      pid=$!
      echo $pid > %opt(text_terminal_fifos)/pid
      wait
    }
    set-option -add global text_terminal_counter 1
    map buffer insert <s-ret> '<esc>: send-prompt-to-pty<ret>A'
    map buffer normal <s-ret> ': send-prompt-to-pty<ret>'
    try ansi-enable
    set-option buffer text_terminal_fifos %opt(text_terminal_fifos)

    # Kill the terminal process when the buffer closes.
    hook -always -once buffer BufClose .* %{ nop %sh{
      if [ -d "$kak_opt_text_terminal_fifos" ]; then
        kill "$(cat "$kak_opt_text_terminal_fifos/pid")"
        rm -rf "$kak_opt_text_terminal_fifos"
      fi
    }}
    hook -always -once buffer BufCloseFifo .* %{ nop %sh{
      if [ -d "$kak_opt_text_terminal_fifos" ]; then
        kill "$(cat "$kak_opt_text_terminal_fifos/pid")"
        rm -rf "$kak_opt_text_terminal_fifos"
      fi
    }}

  }
}
