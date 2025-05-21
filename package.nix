{ lib, rustPlatform, pkg-config, cmake, openssl, libpq, ... }:

let
  manifest = (lib.importTOML ./Cargo.toml).package;
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = manifest.name;
  inherit (manifest) version;

  src = lib.cleanSource ./.;

  cargoHash = "sha256-C6TU4Lh4u6BgOzzI4+VLLpqCVEMAzsddYuzFGAyAdFI=";

  cargoBuildFlags = "-p ${finalAttrs.pname}";
  cargoTestFlags = "-p ${finalAttrs.pname}";

  nativeBuildInputs = [ pkg-config cmake ];

  buildInputs = [ openssl libpq ];

  meta = {
    mainProgram = "bureaucrat";
    description = "Service which feeds a redis instance with geo data";
    homepage = "https://github.com/tlm-solutions/bureaucrat";
  };
})

