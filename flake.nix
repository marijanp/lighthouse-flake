{
  inputs = {
    dreampkgs.url = "github:nix-community/dreampkgs";
  };
  outputs = { nixpkgs, dreampkgs, ... }: {
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
