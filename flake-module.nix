{ lib, flake-parts-lib, ... }:
let
  inherit (flake-parts-lib) mkPerSystemOption;
  inherit (lib) mkOption types warn;
in {
  options = {
    perSystem = mkPerSystemOption ({ ... }: {
      options.lighthouse = mkOption {
        default = warn "lighthouse-flake module was imported but not used" { };
        description = ''
          **lighthouse-flake**: Creates a Google lighthouse test-run for each of the defined test attributes,
          which can be configured by setting the to be tested dist directory and specifying the criteria.
          Checks **succeed** or **fail** depending on whether the defined **minimal score** for each of the criteria
          is reached.
        '';
        type = types.submodule {
          options = {
            package = mkOption { type = types.package; };

            tests = mkOption {
              type = types.attrsOf (types.submodule {
                options = {
                  dist = mkOption {
                    type = types.path;
                    description = ''
                      Path to static directory to test. Great for static site generators.
                    '';
                  };

                  categories = mkOption {
                    default = { };
                    type = types.submodule {
                      options = {
                        performance = mkOption {
                          type = types.numbers.between 0 1;
                          default = 0.9;
                          description = ''
                            The minimal score that should be reached for *performance*.
                          '';
                        };
                        accessibility = mkOption {
                          type = types.numbers.between 0 1;
                          default = 0.9;
                          description = ''
                            The minimal score that should be reached for *accessibility*.
                          '';
                        };
                        seo = mkOption {
                          type = types.numbers.between 0 1;
                          default = 0.9;
                          description = ''
                            The minimal score that should be reached for *SEO*.
                          '';
                        };
                        bestPractices = mkOption {
                          type = types.numbers.between 0 1;
                          default = 0.9;
                          description = ''
                            The minimal score that should be reached for *best practices*.
                          '';
                        };
                      };
                    };
                  };
                };
              });
            };
          };
        };
      };
    });
  };

  config = {
    perSystem = { config, pkgs, ... }:
      {
        checks = lib.mapAttrs (name: test:
          pkgs.callPackage ./nixos-test.nix {
            inherit name test;
            google-lighthouse = config.lighthouse.package;
          }
        ) config.lighthouse.tests;
      };
  };
}

