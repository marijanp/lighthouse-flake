{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    lighthouse-flake.url = "github:marijanp/lighthouse-flake";
  };

  outputs = inputs@{ self, flake-parts, lighthouse-flake, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [ lighthouse-flake.flakeModule ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        lighthouse = {
          tests = {
            "test-frontend" = {
              dist = ./dist;
              categories = {
                performance = 0.95;
                accessibility = 0.95;
                seo = 1.0;
                bestPractices = 0.95;
              };
            };
            "test-frontend-other" = { dist = ./dist; };
          };
        };
      };
    };
}
