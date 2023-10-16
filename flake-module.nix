{ self, lib, flake-parts-lib, ... }:
let
  inherit (flake-parts-lib)
    mkPerSystemOption;
  inherit (lib)
    mdDoc
    mkOption
    types
    warn;
in
{
  options = {
    perSystem = mkPerSystemOption
      ({ config, self', inputs', pkgs, system, ... }: {
        options.lighthouse = mkOption {
          default = warn "lighthouse flake module was imported but not used" { };
          description = mdDoc ''
            lighthouse-flake: Creates a Google lighthouse test-run for a given dist directory
            and creates a flake check output for it. Checks succeed or fail depending on the criteria
            defined in the config.
          '';
          type = types.submodule {
            options = {
              package = mkOption {
                type = types.package;
              };
              dist = mkOption {
                type = types.path;
              };

              categories = mkOption {
                default = { };
                type = types.submodule {
                  options = {
                    performance = mkOption {
                      type = types.float;
                      default = 0.9;
                      description = mdDoc ''
                        The minimal score that should be reached for *performance*.
                      '';
                    };
                    accessibility = mkOption {
                      type = types.float;
                      default = 0.9;
                      description = mdDoc ''
                        The minimal score that should be reached for *accessibility*.
                      '';
                    };
                    seo = mkOption {
                      type = types.float;
                      default = 0.9;
                      description = mdDoc ''
                        The minimal score that should be reached for *SEO*.
                      '';
                    };
                    bestPractices = mkOption {
                      type = types.float;
                      default = 0.9;
                      description = mdDoc ''
                        The minimal score that should be reached for *best practices*.
                      '';
                    };
                  };
                };
              };
            };
          };
        };
      });
  };

  config = {
    perSystem = { config, self', inputs', pkgs, ... }:
      let
        dist = config.lighthouse.dist;
        server-port = 8080;
        checks.lighthouse = pkgs.nixosTest {
          name = "lighthouse-test";
          nodes = {
            server = { config, pkgs, ... }: {
              environment.variables.CHROME_PATH = "${pkgs.ungoogled-chromium}/bin/chromium";
              systemd.services.lighthouse-test-server = {
                wantedBy = [ "multi-user.target" ];
                after = [ "network.target" ];
                description = "lighthouse-test-server";
                serviceConfig = {
                  DynamicUser = true;
                  ExecStart = ''${pkgs.simple-http-server}/bin/simple-http-server -c=js,css,svg,html -i -p ${builtins.toString server-port} -- ${dist}'';
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
            server.succeed("CI=1 ${config.lighthouse.package}/bin/lighthouse http://localhost:${builtins.toString server-port} --output json --output-path {} --only-categories accessibility,best-practices,performance,seo --skip-audits valid-source-maps --chrome-flags=\"--headless --no-sandbox\"".format(report_path))
            server.copy_from_vm(report_path)
            with open("{}/lighthouse-report.json".format(os.environ["out"]), "r") as f:
              report = json.load(f)
              categories = report["categories"]
              
              performance_score = categories["performance"]["score"]
              assert performance_score >= ${toString config.lighthouse.categories.performance}, "performance score should be at least ${toString config.lighthouse.categories.performance}, but was {}".format(performance_score)

              accessibility_score = categories["accessibility"]["score"]
              assert accessibility_score >= ${toString config.lighthouse.categories.accessibility}, "accessibility score should be at least ${toString config.lighthouse.categories.accessibility}, but was {}".format(accessibility_score)

              seo_score = categories["seo"]["score"]
              assert seo_score >= ${toString config.lighthouse.categories.seo}, "seo score should be at least ${toString config.lighthouse.categories.seo}%, but it was {}".format(seo_score)

              best_practices_score = categories["best-practices"]["score"]
              assert best_practices_score >= ${toString config.lighthouse.categories.bestPractices}, "best-practices score should be at least ${toString (config.lighthouse.categories.bestPractices)}"
          '';
        };
      in
      {
        inherit checks;
      };
  };
}

