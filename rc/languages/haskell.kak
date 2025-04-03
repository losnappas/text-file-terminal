provide-module -override text-terminal-haskell %{

try %{
  declare-option -hidden str text_terminal_start_haskell 'stack repl'
}

define-command -override start-pty-haskell %{
  set-option local text_terminal_script_args %exp{-c "%opt(text_terminal_start_haskell)"}
  start-pty
}

define-command -override -params 0..1 send-to-pty-haskell %{
  send-to-pty ":{"
  evaluate-commands %sh{
    kak_escape() {
      echo "$@" | sed 's/"/""/g'
    }
    if [ $# -eq 0 ]; then
      eval set -- "$kak_quoted_selections"
    fi
    for sel in "$@"; do
      printf 'send-to-pty "%s"\n' "$(kak_escape "$sel")"
    done
  }
  send-to-pty ":}"
}

define-command -override -docstring 'Reload file on save' haskell-repl-reload-enable %{
  remove-hooks buffer text-terminal-haskell-reload
  hook -group text-terminal-haskell-reload buffer BufWritePost .* %{
    try %{ send-to-pty ":reload" }
  }
}
}
