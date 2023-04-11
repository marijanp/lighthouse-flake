{
  inputs = {
    dream2nix.url = "github:nix-community/dream2nix";
    lighthouse-src.url = "github:GoogleChrome/lighthouse/v10.1.0";
    lighthouse-src.flake = false;
  };
  outputs = { self, dream2nix, ... }:
    {
      inherit (dream2nix.lib.makeFlakeOutputs {
        systems = [ "x86_64-linux" ];
        source = self.inputs.lighthouse-src;
        autoProjects = true;
        config.projectRoot = ./.;
      }) packages;
    };
}
