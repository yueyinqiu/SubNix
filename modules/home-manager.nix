{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.subnix;

  mkSubDerivationFor = import ../lib/mk-sub-derivation.nix;

  mkSubDerivation = args: mkSubDerivationFor pkgs (args // { sub = cfg.package; });

  cliDrvs = lib.mapAttrs (
    name: cli:
    mkSubDerivation {
      pname = name;
      version = cli.version;
      command = cli.command;
      src = cli.scripts;
      runtimeInputs = cli.runtimeInputs;
    }
  ) cfg.clis;
in
{
  options.programs.subnix = {
    enable = lib.mkEnableOption "sub-based CLIs";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../packages/sub.nix { };
      defaultText = lib.literalExpression "pkgs.callPackage ../packages/sub.nix { }";
      description = "The `sub` package to install.";
    };

    clis = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }: {
            options = {
              scripts = lib.mkOption {
                type = lib.types.path;
                description = ''
                  Directory containing a `libexec/` directory (and optionally a
                  `lib/` directory for shared code).
                '';
              };

              version = lib.mkOption {
                type = lib.types.str;
                description = "Version of this CLI.";
              };

              command = lib.mkOption {
                type = lib.types.str;
                default = name;
                description = "Command name, defaults to the attribute name.";
              };

              runtimeInputs = lib.mkOption {
                type = lib.types.listOf lib.types.package;
                default = [ ];
                description = "Runtime dependencies prepended to `PATH`.";
              };
            };
          }
        )
      );
      default = { };
      description = "Attribute set of sub-based CLIs to build and install.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ] ++ lib.attrValues cliDrvs;
  };
}
