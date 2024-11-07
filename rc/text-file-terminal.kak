provide-module text-file-terminal %{
  declare-option -docstring 'shell path' str text_file_terminal_shell_exec 'bash'
  declare-option -docstring 'fifo' -hidden str text_file_terminal_fifo_path
  # python3 -m text_file_terminal.main
  declare-option -docstring 'text-file-terminal path' str text_file_terminal_exec 'text-file-terminal'

  define-command -override text-file-terminal-send-shell-cmd %{
    evaluate-commands -draft %{
      execute-keys -save-regs '' '%'
      try %{
        execute-keys '<a-k>\S<ret>'
        echo -to-file %opt(text_file_terminal_fifo_path) -quoting raw %reg(dot)
        execute-keys '<a-d>'
      }
    }
  }

  define-command -override text-file-terminal-open-shell %{
    evaluate-commands %sh{
      tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/text-file-terminal.XXXXXX")"
      fifo="$tmpdir/fifo"
      mkfifo "$fifo"
      printf "set-option global text_file_terminal_fifo_path '%s'\n" "$fifo"
    }
    evaluate-commands -try-client %opt{toolsclient} %{
      fifo -name '*text-terminal*' -scroll -- eval %opt(text_file_terminal_exec) --commands-fifo %opt(text_file_terminal_fifo_path) --sh-binary %opt(text_file_terminal_shell_exec) --cols %val(window_width) --rows %val(window_height)
    }
  }

  hook -always -group text-file-terminal global BufClose \*text-terminal\* %{ nop %sh{
    if [ -f "$kak_opt_text_file_terminal_fifo_path" ]; then
      # Should close the forked/setsid program somehow.
      rm -rf "$kak_opt_text_file_terminal_fifo_path"
    fi
  }}

  hook -group text-file-terminal global BufOpenFifo \*text-terminal\* %{
    ansi-enable
  }

  hook -group text-file-terminal global BufCreate \*text-terminal-input\* %{
    set-option buffer filetype 'bash'
  }

  hook -always -group text-file-terminal global KakEnd .* %{
    nop %sh{
      if [ -f "$kak_opt_text_file_terminal_fifo_path" ]; then
        rm -rf "$kak_opt_text_file_terminal_fifo_path"
      fi
    }
  }

  define-command -override text-file-terminal-open-input %{
    edit -scratch *text-terminal-input*
  }
}
