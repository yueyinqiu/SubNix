{
  lib,
  rustPlatform,
  src,
}:

rustPlatform.buildRustPackage {
  pname = "sub";
  # Keep in sync with upstream Cargo.toml.
  version = "2.3.1";

  inherit src;

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
  };

  meta = {
    description = "Dynamically generate rich CLIs from scripts";
    homepage = "https://github.com/juanibiapina/sub";
    license = lib.licenses.mit;
    mainProgram = "sub";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
