{ lib, rustPlatform, pkg-config, openssl, protobuf, libpq, ... }:

let
  manifest = (lib.importTOML ./Cargo.toml).package;
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = manifest.name;
  inherit (manifest) version;

  src = lib.cleanSource ./.;

  cargoHash = "sha256-EgaKMmLbM5ncZXEZ3IvO+1mICZjLlIZDm4sdZY08yN4=";

  cargoBuildFlags = "-p ${finalAttrs.pname}";
  cargoTestFlags = "-p ${finalAttrs.pname}";

  nativeBuildInputs = [ pkg-config protobuf ];

  buildInputs = [ openssl libpq ];

  meta = {
    mainProgram = "bureaucrat";
    description = "Service which feeds a redis instance with geo data";
    homepage = "https://github.com/tlm-solutions/bureaucrat";
  };
})

