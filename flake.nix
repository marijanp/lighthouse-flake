{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };
  outputs = { nixpkgs, ... }: {
    formatter."x86_64-linux" = nixpkgs.legacyPackages."x86_64-linux".nixfmt;
    templates.default = {
      path = ./templates/default;
      description = "lighthouse-flake flake-parts template";
    };
    flakeModule = {
      imports = [ ./flake-module.nix ];
      perSystem = { pkgs, ... }: {
        lighthouse.package = pkgs.google-lighthouse;
      };
    };
  };
}
