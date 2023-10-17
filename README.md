# lighthouse-flake

A [flake-parts](https://flake.parts/) module for Google's web page and web app auditing tool called [lighthouse](https://github.com/GoogleChrome/lighthouse). Enabling and configuring this flake-parts module adds a check output to your flake, which will pass or fail depending on your specified criteria running it locally or in your CI pipeline.

## Usage

The following snippet shows how one can define a lighthouse test called *test-frontend* and *test-frontend-other*.
For each test, it's required to set the dist directory that should be tested.
Optionally, it's possible to specify the minimal score that needs to be reached for the check to succeed.
All the minimal scores can be set to a value between 0.0 and 1.0 (i.e. 0% and 100%) and default to 0.9 (i.e. 90%).
'lighthouse-flake' will take each of the test attributes and transform them into [NixOS tests](https://nix.dev/tutorials/nixos/integration-testing-using-virtual-machines).
Each test spins up a virtual machine serving the defined dist directory using [http-server-simple](https://github.com/TheWaWaR/simple-http-server), then lighthouse is run and the scores are checked.

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    lighthouse-flake.url = "github:marijanp/-flake";
  };

  outputs = inputs@{ self, flake-parts, lighthouse-flake, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [
        lighthouse-flake.flakeModule
      ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
        {
          lighthouse = {
            tests = {
              "test-frontend" = {
                dist = ./dist;
                categories = {
                  performance = 0.95;
                  accessibility = 0.95;
                  seo = 0.95;
                  bestPractices = 0.95;
                };
              };
              "test-frontend-other" = {
                dist = ./dist;
                # if not specified, the minimal scores will be 0.9
              };
            };
          };
        };
    };
}
```
