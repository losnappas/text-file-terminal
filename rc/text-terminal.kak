provide-module -override text-terminal %{
  declare-option -docstring 'Extra args to `script`, e.g. `-c bash`' str text_terminal_script_args
  declare-option -hidden str text_terminal_fifos
  declare-option -hidden str text_terminal_prompt_start_position

  remove-hooks global text-terminal-filetypes
  remove-hooks global text-terminal-default-keybinds

  define-command -override -hidden ansi-render-selection-impl %{
      evaluate-commands -save-regs | %{
          set-register '|' "%opt{ansi_filter} -range %val{selection_desc} 2>%opt{ansi_command_file}"
          execute-keys "|<ret>"
          update-option buffer ansi_color_ranges
          source "%opt{ansi_command_file}"
          trigger-user-hook "AnsiColored=%val(selection_desc)"
      }
  }

  define-command -hidden -override -docstring 'Send current prompt to the terminal' send-prompt-to-pty %{
    evaluate-commands -draft -save-regs '"/' %{
      select "%opt(text_terminal_prompt_start_position),9999999.9999999"

      execute-keys -draft -save-regs . "a<esc>"
      execute-keys _

      # Send to input fifo.
      send-to-pty %reg(dot)
    }
    execute-keys -with-hooks geA
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
      tail -f %opt(text_terminal_fifos)/in | TERM=vt-100 script %opt(text_terminal_script_args) -qf /dev/null -Enever &
      pid=$!
      echo $pid > %opt(text_terminal_fifos)/pid
      wait
    }
    hook -always -once buffer BufClose .* kill-pty
    hook -always -once buffer BufCloseFifo .* kill-pty
    hook -group text-terminal-hook buffer User AnsiColored=.*,(?<start>.*) %{
      set-option buffer text_terminal_prompt_start_position "%val(hook_param_capture_start)"
    }

    try ansi-enable
    set-option buffer text_terminal_fifos %opt(text_terminal_fifos)
    execute-keys -with-hooks geA
  }

  define-command -docstring 'Kills the repl process' -hidden -override kill-pty %{ nop %sh{
    if [ -d "$kak_opt_text_terminal_fifos" ]; then
      kill "$(cat "$kak_opt_text_terminal_fifos/pid")"
      rm -rf "$kak_opt_text_terminal_fifos"
    fi
  }}

  hook -group text-terminal-default-keybinds global BufCreate ^\*shell\*$ %{
    map buffer insert <ret> '<esc>: send-prompt-to-pty<ret>'
    map buffer normal <s-ret> ': send-to-pty "%val(selection)"<ret>'
  }

  hook -group text-terminal-filetypes global BufSetOption filetype=(clojure|haskell) %{
    try %{
      require-module "text-terminal-%val(hook_param_capture_1)"
    }
  }
}

provide-module -override text-terminal-history %{
  require-module peneira
  remove-hooks global text-terminal-history

  define-command -override -hidden -params .. peneira-insert-selection %{
    evaluate-commands -save-regs p %{
      set-register p "%arg(@)"
      execute-keys <esc>"p<a-p>a
    }
  }

  hook -group text-terminal-history global BufCreate ^\*shell\*$ %{
    map buffer insert <a-r> '<esc>: peneira "> " %{ tac "${HISTFILE:-~/.bash_history}" } %{ peneira-insert-selection %arg(@) }<ret>'
  }
}
