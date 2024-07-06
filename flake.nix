{
  inputs = {
    dreampkgs.url = "github:nix-community/dreampkgs";
    nixpkgs.follows = "dreampkgs/nixpkgs";
  };
  outputs = { nixpkgs, dreampkgs, ... }: {
    formatter."x86_64-linux" = nixpkgs.legacyPackages."x86_64-linux".nixfmt;
    templates.default = {
      path = ./templates/default;
      description = "lighthouse-flake flake-parts template";
    };
    flakeModule = {
      imports = [ ./flake-module.nix ];
      perSystem = { system, ... }: {
        lighthouse.package = dreampkgs.packages.${system}.lighthouse;
      };
    };
  };
}
