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

            # packages = with pkgs; [
            #   unixtools.script
            # ];

            # enterShell = '''';
          };

          formatter = pkgs.nixfmt-rfc-style;

          packages.default = pkgs.kakouneUtils.buildKakounePluginFrom2Nix {
            pname = "kak-text-file-terminal";
            version = "1.0.0";
            src = ./rc;
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
            in
            {
              options.programs.kakoune.text-file-terminal = {
                enable = mkEnableOption "kak-text-file-terminal";
              };
              config = mkIf cfg.enable {
                programs.kakoune.plugins = [
                  (self.packages.${pkgs.stdenv.hostPlatform.system}.default)
                ];
              };
            };
        };
      };
    };
}
