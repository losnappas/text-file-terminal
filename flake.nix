{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs self; } {
      imports = [
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
          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              unixtools.script
              nil
              bash-language-server
              shellcheck-minimal
            ];
          };

          formatter = pkgs.nixfmt-tree;

          packages.default = pkgs.kakouneUtils.buildKakounePluginFrom2Nix {
            pname = "kak-text-file-terminal";
            version = "1.1.0";
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
