# Build a CLI package from a source tree containing a `libexec/` directory
# (and optionally a `lib/` directory for shared code).
#
# `sub` is the `sub` binary the generated entry point runs; it defaults to
# this flake's own package and can be overridden per call:
#
#   mkSubDerivation pkgs {
#     pname = "hat";
#     version = "1.0.0";
#     src = ./.;
#     runtimeInputs = [ pkgs.jq ];
#   }
#
# `runtimeInputs` are runtime dependencies: they are prepended to `PATH` by the
# generated entry point, so scripts can call them.
pkgs:
{
  pname,
  version,
  command ? pname,
  sub ? pkgs.callPackage ../packages/sub.nix { },
  runtimeInputs ? [ ],
  src,
  meta ? { },
  passthru ? { },
}:
let
  entryScript = pkgs.writeShellApplication {
    name = command;
    inherit runtimeInputs;
    text = ''
      exec ${sub}/bin/sub --name ${command} --absolute "@out@/root" -- "$@"
    '';
  };

  bashCompletion = pkgs.writeText command ''
    _${command}() {
      local cur="''${COMP_WORDS[COMP_CWORD]}"
      local -a args=("''${COMP_WORDS[@]:1:COMP_CWORD-1}")
      COMPREPLY=( $(compgen -W "$(@out@/bin/${command} --completions "''${args[@]}")" -- "$cur") )
    }
    complete -F _${command} ${command}
  '';
in
pkgs.stdenv.mkDerivation {
  inherit
    pname
    src
    version
    meta
    passthru
    ;
  buildPhase = "true";
  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    cp -a . $out/root/

    install -Dm755 ${entryScript}/bin/${command} $out/bin/${command}
    substituteInPlace $out/bin/${command} --replace-fail "@out@" "$out"
    install -Dm644 ${bashCompletion} $out/share/bash-completion/completions/${command}
    substituteInPlace $out/share/bash-completion/completions/${command} --replace-fail "@out@" "$out"

    runHook postInstall
  '';
}
