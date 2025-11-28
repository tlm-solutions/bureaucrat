{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = (import nixpkgs) {
            inherit system;
          };
          bureaucrat = pkgs.callPackage ./package.nix { };
        in
        {
          packages = {
            inherit bureaucrat;
            default = bureaucrat;
            docs = (pkgs.nixosOptionsDoc {
              options = (nixpkgs.lib.nixosSystem {
                inherit system;
                modules = [ self.nixosModules.default ];
              }).options.TLMS;
            }).optionsCommonMark;
          };

          devShells.default = pkgs.mkShell {
            nativeBuildInputs = with bureaucrat; nativeBuildInputs ++ buildInputs;
          };
        }
      ) // {
      overlays.default = _: prev: {
        inherit (self.packages."${prev.system}") bureaucrat;
      };

      nixosModules = rec {
        bureaucrat = ./module.nix;
        default = bureaucrat;
      };
    };
}
