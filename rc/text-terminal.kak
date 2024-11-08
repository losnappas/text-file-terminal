provide-module -override text-terminal %{
  declare-option -hidden int text_terminal_counter 0
  declare-option -docstring 'Path to `script(1)` program' str text_terminal_script_exec 'script'
  declare-option -hidden str text_terminal_fifos
  # Match up to non-trailing space after ' $ ', it will be the input prompt.
  # Would've used ' \$ (.+?)' but idk how to get the capture group register then? Doesn't seem to be on %reg(1).
  # Now it has a loobehind that works.
  declare-option -docstring 'Prompt string that will be searched for' regex text_terminal_prompt_matcher ' \$ '

  define-command -hidden -override -docstring 'Send current prompt to the terminal' send-prompt-to-pty %{
    evaluate-commands -draft -save-regs dquote %{
      # Match the prompt.
      set-register / %opt(text_terminal_prompt_matcher)
      # Get prompt -> select everything after it.
      execute-keys -save-regs '' "ge<a-/><ret>/.*[^\s]<ret>d"

      # Send to input fifo.
      send-to-pty %reg(dquote)
    }
    execute-keys ge
  }

  define-command send-to-pty -params 1 -docstring 'Send to the terminal. E.g. `send-to-pty "exit\n"' %{
    echo -end-of-line -to-file "%opt(text_terminal_fifos)/in" %arg(@)
  }

  define-command -override start-pty %{
    set-option current text_terminal_fifos %sh{
      fifo_dir="$(mktemp -d "${TMP:-/tmp}/kak-text-terminal.XXXXXX")"
      mkfifo "$fifo_dir/in"
      printf "%s" "$fifo_dir"
    }
    fifo -name *shell-%opt(text_terminal_counter)* -script %exp{
      tail -f %opt(text_terminal_fifos)/in | script -qf /dev/null
    }
    set-option -add global text_terminal_counter 1
    map buffer insert <s-ret> '<esc>: send-prompt-to-pty<ret>A'
    map buffer normal <s-ret> ': send-prompt-to-pty<ret>'
    try ansi-enable
    set-option buffer text_terminal_fifos %opt(text_terminal_fifos)
  }
}
