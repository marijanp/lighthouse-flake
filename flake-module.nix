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
                  dist = mkOption { type = types.path; };

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
      let
        checks = lib.mapAttrs (name: test:
          pkgs.nixosTest {
            inherit name;
            nodes = {
              server = { pkgs, config, ... }: {
                virtualisation.cores = 4;

                environment.variables.CHROME_PATH =
                  lib.getExe pkgs.ungoogled-chromium;

                services.h2o = {
                  enable = true;
                  settings = {
                     compress = "ON";
                     http2-reprioritize-blocking-assets = "ON";
                     ssl-offload = "kernel";
                  };
                  hosts."acme.test" = {
                    tls = {
                      recommendations = "modern";
                      policy = "force";
                      identity = [
                        {
                          key-file = pkgs.path + "/nixos/tests/common/acme/server/acme.test.key.pem";
                          certificate-file = pkgs.path + "/nixos/tests/common/acme/server/acme.test.cert.pem";
                        }
                      ];
                    };
                    settings = {
                      paths."/" = {
                        "file.dir" = test.dist;
                      };
                    };
                   };
                };

                networking = {
                  firewall.allowedTCPPorts = [ config.services.h2o.defaultTLSListenPort ];
                  extraHosts = ''
                    127.0.0.1 acme.test
                  '';
                };
                # Required to make TLS work
                security.pki.certificates = [
                  (builtins.readFile (pkgs.path + "/nixos/tests/common/acme/server/ca.cert.pem"))
                ];
              };
            };

            testScript = { nodes, ... }: ''
              import json
              import os

              start_all()
              server.wait_for_open_port(${builtins.toString nodes.server.services.h2o.defaultTLSListenPort})
              server.wait_for_unit("h2o.service")

              report_path = "/tmp/lighthouse-report.json"

              server.succeed("CI=1 ${lib.getExe config.lighthouse.package} https://acme.test --output json --output-path {} --only-categories accessibility,best-practices,performance,seo --skip-audits valid-source-maps --chrome-flags=\"--headless --no-sandbox\"".format(report_path))

              server.copy_from_vm(report_path)

              with open("{}/lighthouse-report.json".format(os.environ["out"]), "r") as f:
                report = json.load(f)
                categories = report["categories"]

                performance_score = categories["performance"]["score"]
                assert performance_score >= ${
                  toString test.categories.performance
                }, "performance score should be at least ${
                  toString test.categories.performance
                }, but it was {}".format(performance_score)

                accessibility_score = categories["accessibility"]["score"]
                assert accessibility_score >= ${
                  toString test.categories.accessibility
                }, "accessibility score should be at least ${
                  toString test.categories.accessibility
                }, but it was {}".format(accessibility_score)

                seo_score = categories["seo"]["score"]
                assert seo_score >= ${
                  toString test.categories.seo
                }, "seo score should be at least ${
                  toString test.categories.seo
                }, but it was {}".format(seo_score)

                best_practices_score = categories["best-practices"]["score"]
                assert best_practices_score >= ${
                  toString test.categories.bestPractices
                }, "best-practices score should be at least ${
                  toString (test.categories.bestPractices)
                }, but it was {}".format(best_practices_score)
            '';
          }) config.lighthouse.tests;
      in { inherit checks; };
  };
}

