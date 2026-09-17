{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "sub";
  version = "2.3.1";

  src = fetchFromGitHub {
    owner = "juanibiapina";
    repo = "sub";
    rev = "v${version}";
    hash = "sha256-iE8b912YGlJ3ibezxScrc9T0up7jVjECPWtbr0edIuo=";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
  };

  meta = {
    description = "Dynamically generate rich CLIs from scripts";
    homepage = "https://github.com/juanibiapina/sub";
    license = lib.licenses.mit;
    mainProgram = "sub";
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
    ];
  };
}
