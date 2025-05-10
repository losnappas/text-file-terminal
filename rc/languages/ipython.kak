provide-module -override text-terminal-ipython %{
try %{
  # The input is duplicated currently, that's a bug caused here.
  # `--simple-prompt` shows no input at all.
  declare-option -hidden str text_terminal_start_ipython 'ipython'
}

define-command -override start-pty-ipython %{
  set-option local text_terminal_script_args %exp{-c "%opt(text_terminal_start_ipython)"}
  start-pty
}

define-command -override send-to-pty-ipython-cell %{
  evaluate-commands -draft %{
    select-ipython-cell

    evaluate-commands -itersel %{
      send-to-pty "%reg(dot)"
    }
  }
}

define-command -override -docstring %{
  Select code in a `# %%` cell
} select-ipython-cell %{
  evaluate-commands -itersel %{
    # Select start of "# %%" cell
    try %{
      # Will get rekt if `# %%` isn't at start of line. The regex engine doesn't allow \s* in lookbehinds.
      execute-keys -save-regs '' %{;<a-/>(?<lt>=# %%)<ret>jx}
    } catch %{
      execute-keys -save-regs '' %{gg}
    }

    # Select end of same cell
    try %{
      execute-keys -save-regs '' %{?.*?(?=# %%)<ret>}
    } catch %{
      execute-keys -save-regs '' %{Ge}
    }
  }
}
}
