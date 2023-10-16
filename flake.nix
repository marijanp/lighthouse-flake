{
  inputs = {
    dreampkgs.url = "github:nix-community/dreampkgs";
  };
  outputs = { self, dreampkgs, ... }:
    {
      flakeModule = {
        imports = [ ./flake-module.nix ];
        perSystem = { system, ... }:
          {
            lighthouse.package = dreampkgs.packages.${system}.lighthouse;
          };
      };
    };
}
