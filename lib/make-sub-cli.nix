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
  entry = pkgs.writeShellApplication {
    name = command;
    inherit runtimeInputs;
    text = ''
      exec "${sub}/bin/sub" --name "${command}" --absolute "@out@/root" -- "$@"
    '';
  };

  bashCompletion = pkgs.writeText command ''
    _${command}() {
      local cur="''${COMP_WORDS[COMP_CWORD]}"
      local -a args=("''${COMP_WORDS[@]:1:COMP_CWORD-1}")
      COMPREPLY=( $(compgen -W "$("@out@/bin/${command}" --completions "''${args[@]}")" -- "$cur") )
    }
    complete -F "_${command}" "${command}"
  '';
in
pkgs.stdenv.mkDerivation {
  pname = pname;
  src = src;
  version = version;
  meta = meta;
  passthru = passthru;
  buildPhase = "true";
  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"

    cp -a . "$out/root/"

    install -Dm755 "${entry}/bin/${command}" "$out/bin/${command}"
    substituteInPlace "$out/bin/${command}" --replace-fail "@out@" "$out"
    install -Dm644 "${bashCompletion}" "$out/share/bash-completion/completions/${command}"
    substituteInPlace "$out/share/bash-completion/completions/${command}" --replace-fail "@out@" "$out"

    runHook postInstall
  '';
}
