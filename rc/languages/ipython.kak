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
  evaluate-commands -save-regs x %{
    set-register x %val(selections_desc)
    execute-keys %{<esc>%S^# %%<ret>}
    evaluate-commands %sh{
      keep_sels=""
      for regx in $kak_reg_x; do
        for sel in $kak_selections_desc; do
          IFS='.,' read -r x1 x2 x3 x4 <<-EOF
$regx
EOF
          IFS='.,' read -r a1 a2 a3 a4 <<-EOF
$sel
EOF
          # printf 'echo -debug x:%s sel:%s\n' "$x1 $x2 $x3 $x4" "$a1 $a2 $a3 $a4"
          if [ $x1 -ge $a1 ] && [ $x3 -le $a3 ]; then
            keep_sels+="$a1.$a2,$a3.$a4 "
          fi
        done
      done
      # printf '%s\n' "echo -debug keeping sel $keep_sels"
      printf '%s\n' "
        select ${keep_sels:-$kak_reg_x}
        execute-keys <a-x>
      "
    }
  }
}
}
