{
  description = "Nix packaging and modules for sub: scripts with superpowers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      # Only the platforms upstream ships release binaries for.
      eachSystem = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-darwin"
      ];

    in
    {
      packages = eachSystem (system: {
        sub = nixpkgs.legacyPackages.${system}.callPackage ./packages/sub.nix { };
      });

      lib = eachSystem (system: {
        makeSubCli = import ./lib/mk-sub-derivation.nix nixpkgs.legacyPackages.${system};
      });

      homeManagerModules.default = ./modules/home-manager.nix;

      nixosModules.default = ./modules/nixos.nix;

      formatter = eachSystem (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
