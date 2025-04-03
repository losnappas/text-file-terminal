# Programs required:
# leiningen (lein)
#
# Example keybind (clojure files):
# map buffer user e '<esc>: send-to-pty-clojure "%val(selection)"<ret>'
#
# Other repls:
# bb:
# set-option global text_terminal_start_clojure 'bb repl'

provide-module -override text-terminal-clojure %{
try %{
# declare-option -hidden str text_terminal_start_clojure 'bb nrepl-server'
  declare-option -hidden str text_terminal_start_clojure 'lein repl :start'
  declare-option -hidden str text_terminal_clojure_nrepl_namespace 'user'
}

define-command -override start-pty-clojure %{
  set-option local text_terminal_script_args %exp{-c "%opt(text_terminal_start_clojure)"}
  start-pty
}

define-command -override -params 1 send-to-pty-clojure %{
  nrepl-update-namespace
  send-to-pty %arg(@)
}

define-command -override send-to-pty-clojure-selections %{
  nrepl-update-namespace
  evaluate-commands -itersel %{
    send-to-pty "%reg(dot)"
  }
}

define-command -hidden -override nrepl-update-namespace %{
  nrepl-find-namespace
  send-to-pty "(in-ns '%opt(text_terminal_clojure_nrepl_namespace))"
}

define-command -override -hidden nrepl-find-namespace %{
  evaluate-commands -draft %{
    set-option global text_terminal_clojure_nrepl_namespace 'user'
    try %{
      execute-keys 'gg/^\(ns\s+(\S+)<ret>'
      set-option global text_terminal_clojure_nrepl_namespace %reg{1}
    }
  }
}

define-command -override -docstring 'Load current file' clojure-repl-load-file %{
  send-to-pty "(in-ns 'user)"
  send-to-pty %exp{(load-file "%val(bufname)")}
}
}
