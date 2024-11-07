# kak-text-file-terminal

Kakoune text editor integration.

## Install

You could use pip & copy the rc file (and do `set-option` for `text_file_terminal_exec` with the correct executable then).

Or nix w/ home manager:

```nix
# Home manager flake config.
inputs.text-file-terminal = {
  url = "git+file:///home/nsa/projects/text-file-terminal";
  inputs.nixpkgs.follows = "nixpkgs";
};

... # snip

users.${myUserName} = {
  imports = [
    # ...
    inputs.text-file-terminal.hmModules.text-file-terminal
  ];
};

... # snip

programs.kakoune.text-file-terminal.enable = true;
```

## Usage

Integration for kakoune editor is provided in `rc/text-file-terminal.kak`. It depends on [kak-ansi](https://github.com/eraserhd/kak-ansi) for highlighting.

### Bindings

```kakscript
hook global BufCreate \*text-terminal-input\* %{
  # e.g.
  map buffer insert <s-ret> '<esc>: text-file-terminal-send-shell-cmd<ret>i'
}
```

To use it:

- `:text-file-terminal-open-shell<ret>` to start the terminal.
- `:text-file-terminal-open-input<ret>` to open the input box.
- In the input box, hit `<s-ret>` to send (or w.e you bound to above).
