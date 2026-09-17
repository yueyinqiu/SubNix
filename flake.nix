{
  description = "Nix packaging and modules for sub: scripts with superpowers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Upstream source, followed as plain source (not a flake) so we control
    # the build ourselves against a pinned revision instead of upstream's
    # `./.`-based packaging.
    sub-src = {
      url = "github:juanibiapina/sub";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      sub-src,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      eachSystem = nixpkgs.lib.genAttrs systems;

      # Pure, system-agnostic builder: pkgs -> sub -> args -> drv.
      mkSubDerivationFor = import ./lib/mk-sub-derivation.nix;
    in
    {
      packages = eachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          sub = pkgs.callPackage ./packages/sub.nix { src = sub-src; };
        in
        {
          inherit sub;
          default = sub;
        }
      );

      lib = {
        inherit mkSubDerivationFor;
      }
      // eachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          # Convenience, per-system, matching upstream's API: args -> drv.
          mkSubDerivation = mkSubDerivationFor pkgs self.packages.${system}.sub;
        }
      );

      homeManagerModules = {
        default = import ./modules/home-manager.nix {
          inherit mkSubDerivationFor;
          subPackages = eachSystem (system: self.packages.${system}.sub);
        };
      };

      nixosModules = {
        default = import ./modules/nixos.nix {
          inherit mkSubDerivationFor;
          subPackages = eachSystem (system: self.packages.${system}.sub);
        };
      };

      formatter = eachSystem (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
