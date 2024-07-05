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
        server-port = 8080;
        checks = lib.mapAttrs (name: test:
          pkgs.nixosTest {
            inherit name;
            nodes = {
              server = { pkgs, ... }: {
                environment.variables.CHROME_PATH =
                  lib.getExe pkgs.ungoogled-chromium;
                systemd.services.lighthouse-test-server = {
                  wantedBy = [ "multi-user.target" ];
                  after = [ "network.target" ];
                  description = "lighthouse-test-server";
                  serviceConfig = {
                    DynamicUser = true;
                    ExecStart = "${
                        lib.getExe pkgs.simple-http-server
                      } -c=js,css,svg,html -i -p ${
                        builtins.toString server-port
                      } -- ${test.dist}";
                  };
                };
              };
            };

            testScript = ''
              import json
              import os

              start_all()
              server.wait_for_open_port(${builtins.toString server-port})

              report_path = "/tmp/lighthouse-report.json"
              server.succeed("CI=1 ${config.lighthouse.package}/bin/lighthouse http://localhost:${
                builtins.toString server-port
              } --output json --output-path {} --only-categories accessibility,best-practices,performance,seo --skip-audits valid-source-maps --chrome-flags=\"--headless --no-sandbox\"".format(report_path))
              server.copy_from_vm(report_path)
              with open("{}/lighthouse-report.json".format(os.environ["out"]), "r") as f:
                report = json.load(f)
                categories = report["categories"]

                performance_score = categories["performance"]["score"]
                assert performance_score >= ${
                  toString test.categories.performance
                }, "performance score should be at least ${
                  toString test.categories.performance
                }, but was {}".format(performance_score)

                accessibility_score = categories["accessibility"]["score"]
                assert accessibility_score >= ${
                  toString test.categories.accessibility
                }, "accessibility score should be at least ${
                  toString test.categories.accessibility
                }, but was {}".format(accessibility_score)

                seo_score = categories["seo"]["score"]
                assert seo_score >= ${
                  toString test.categories.seo
                }, "seo score should be at least ${
                  toString test.categories.seo
                }%, but it was {}".format(seo_score)

                best_practices_score = categories["best-practices"]["score"]
                assert best_practices_score >= ${
                  toString test.categories.bestPractices
                }, "best-practices score should be at least ${
                  toString (test.categories.bestPractices)
                }"
            '';
          }) config.lighthouse.tests;
      in { inherit checks; };
  };
}

