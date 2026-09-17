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
        makeSubCli = import ./lib/make-sub-cli.nix nixpkgs.legacyPackages.${system};
      });

      homeManagerModules.sub-nix = ./home-manager-modules/sub-nix.nix;

      nixosModules.sub-nix = ./nixos-modules/sub-nix.nix;
    };
}
