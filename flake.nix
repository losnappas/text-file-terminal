{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
    systems.url = "github:nix-systems/default";
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devenv.flakeModule
      ];
      systems = import inputs.systems;
      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {

          # Per-system attributes can be defined here. The self' and inputs'
          # module parameters provide easy access to attributes of the same
          # system.

          devenv.shells.default = {
            # https://devenv.sh/reference/options/
            languages.nix.enable = true;
            languages.shell.enable = true;
            languages.python = {
                enable = true;
                venv.enable = true;
            };

            packages = with pkgs; [
              oils-for-unix
              python312Packages.python-lsp-server
              python312Packages.python-lsp-ruff
              python312Packages.pyls-isort
              bashInteractive
            ];

            # enterShell = '''';
          };

          formatter = pkgs.nixfmt-rfc-style;

          packages.default = pkgs.python3Packages.buildPythonApplication {
            version = "1.0.0";
            pname = "text-file-terminal";
            src = ./.;
            format = "pyproject";
            nativeBuildInputs = [ pkgs.makeWrapper ];
            buildInputs = [
              pkgs.python3Packages.setuptools
              pkgs.python3Packages.wheel
            ];
          };

          packages.hmModule = { config, lib, ...}: {
            nixpkgs.overlays = [
              (_: _: {
                kakounePlugins.text-file-terminal = self'.packages.default;
              })
            ];
          };
        };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.

      };
    };
}