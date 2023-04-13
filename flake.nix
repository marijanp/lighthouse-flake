{
  inputs = {
    dream2nix.url = "github:nix-community/dream2nix";
    lighthouse-src.url = "github:GoogleChrome/lighthouse/v10.1.0";
    lighthouse-src.flake = false;
  };
  outputs = { self, dream2nix, ... }:
    let
      pkgs = dream2nix.inputs.nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      inherit (dream2nix.lib.makeFlakeOutputs {
        systems = [ "x86_64-linux" ];
        source = self.inputs.lighthouse-src;
        projects = ./projects.toml;
        config.projectRoot = ./.;
        packageOverrides = {
          "lighthouse".updated.overrideAttrs = old: {
            nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.yarn ];
            patches = [ ./reset-link.patch ];
            postBuild = "npm run build-all";
          };
        };
      }) packages;
    };
}
