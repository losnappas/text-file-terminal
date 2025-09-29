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

  define-command -override -docstring %{
    Make the current buffer's terminal the target of future evals.

    You're expected to be in the shell buffer when running this command.
  } make-current-pty-active %{
    set-option global text_terminal_fifos %opt(text_terminal_fifos)
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

  define-command send-to-pty-as-paste -override -params 0..1 -docstring 'Send to the terminal, as a paste event. E.g. `send-to-pty-as-paste "exit"' %{
    nop %sh{
      printf '\e[200~%s\e[201~\n' "${1:-$kak_reg_dot}" > "$kak_opt_text_terminal_fifos/in"
    }
  }

  define-command send-to-pty -override -params 1 -docstring 'Send to the terminal. E.g. `send-to-pty "exit"' %{
    echo -end-of-line -to-file "%opt(text_terminal_fifos)/in" %arg(@)
  }

  define-command -override start-pty %{
    set-option local text_terminal_fifos %sh{
      fifo_dir="$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/kak-text-terminal.XXXXXX")"
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
    hook -always -once buffer BufCloseFifo .* kill-pty
    hook -group text-terminal-hook buffer User AnsiColored=.*,(?<start>.*) %{
      set-option buffer text_terminal_prompt_start_position "%val(hook_param_capture_start)"
    }

    try ansi-enable
    set-option buffer text_terminal_fifos %opt(text_terminal_fifos)
    make-current-pty-active
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
  hook -group text-terminal-filetypes global BufSetOption filetype=python %{
    try %{
      require-module "text-terminal-ipython"
    }
  }
}

provide-module -override text-terminal-history %{
  remove-hooks global text-terminal-history

  define-command -hidden -override -params 1 text-terminal-paste %{
    evaluate-commands -save-regs p %{
      set-register p "%arg(@)"
      execute-keys <esc>"p<a-P>a
    }
  }

  hook -group text-terminal-history global BufCreate ^\*shell\*$ %{
    map buffer insert <a-r> %{<esc>: prompt -menu -shell-script-candidates %{ tac "${HISTFILE:-~/.bash_history}" }  "> " %{text-terminal-paste "%val(text)"}<ret>}
  }
}
