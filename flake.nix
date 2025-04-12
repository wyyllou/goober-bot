{
  description = "A patch to goober-bot to remove the early-access paywall";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    crane.url = "github:ipetkov/crane";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    {
      self,
      nixpkgs,
      crane,
      systems,
      ...
    }:
    let
      eachSystem = nixpkgs.lib.genAttrs (import systems);
      mkPkgs = system: nixpkgs.legacyPackages.${system};
    in
    {
      inherit self;
      packages = eachSystem (
        system:
        let
          pkgs = mkPkgs system;
          craneLib = crane.mkLib pkgs;
        in
        {
          default = self.packages.${system}.goober-bot;

          goober-bot = craneLib.buildPackage rec {
            src = craneLib.cleanCargoSource ./.;
            cargoArtifacts = craneLib.buildDepsOnly {
              inherit src nativeBuildInputs;
            };
            nativeBuildInputs = with pkgs; [
              pkg-config
              openssl
            ];
          };
        }
      );
      devShells = eachSystem (
        system:
        let
          pkgs = mkPkgs system;
        in
        {
          goober-bot = self.devShells.${system}.default;
          default = pkgs.mkShell {
            inherit (self.packages.${system}.goober-bot) nativeBuildInputs;
          };
        }
      );
    };
}
