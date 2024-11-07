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
    inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs self; } {
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
          lib,
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
            buildInputs = [
              pkgs.python3Packages.setuptools
              pkgs.python3Packages.wheel
            ];
            meta.mainProgram = "text-file-terminal";
          };

          packages.kak-text-file-terminal = pkgs.kakouneUtils.buildKakounePluginFrom2Nix {
            pname = "kak-text-file-terminal";
            version = "1.0.0";
            src = ./rc;
            buildInputs = [
              self'.packages.default
            ];
            postPatch = ''
              substituteInPlace text-file-terminal.kak \
              	--replace-fail \
              	  "text_file_terminal_exec 'text-file-terminal'" \
              	  "text_file_terminal_exec '${lib.getExe self'.packages.default}'" \
              	--replace-fail "bash" "${lib.getExe pkgs.bashInteractive}"
            '';
          };
        };
      flake = {
        hmModules = {
          text-file-terminal =
            {
              config,
              lib,
              pkgs,
              ...
            }:
            with lib;
            let
              cfg = config.programs.kakoune.text-file-terminal;
              localPkgs = self.packages.${pkgs.stdenv.hostPlatform.system};

            in
            {
              options.programs.kakoune.text-file-terminal = {
                enable = mkEnableOption "kak-text-file-terminal";
                package = mkOption {
                  type = types.package;
                  default = localPkgs.kak-text-file-terminal;
                  description = "The package to use for text-file-terminal.";
                };
              };
              config = mkIf cfg.enable {
                # home.packages = [
                #   localPkgs.default
                # ];
                programs.kakoune.plugins = [
                  cfg.package
                ];
              };
            };
        };
      };
    };
}
