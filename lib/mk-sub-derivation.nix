# Build a CLI package from a source tree containing a `libexec/` directory
# (and optionally a `lib/` directory for shared code).
#
# The returned function is intentionally curried so it does not bind to a
# particular system or `sub` package:
#
#   mkSubDerivationFor pkgs sub {
#     pname = "hat";
#     src = ./.;
#     buildInputs = [ pkgs.jq ];
#   }
#
# `buildInputs` are runtime dependencies: they are prepended to `PATH` by the
# generated entry point, so scripts can call them.
pkgs: sub:
{
  pname,
  cmd ? pname,
  buildInputs ? [ ],
  ...
}@args:
let
  inherit (pkgs)
    stdenv
    lib
    bash
    writeTextFile
    ;

  entryScript = writeTextFile {
    name = cmd;
    executable = true;
    destination = "/bin/${cmd}";
    text = ''
      #!${bash}/bin/bash
      set -e
    ''
    + lib.optionalString (buildInputs != [ ]) ''
      export PATH="${lib.makeBinPath buildInputs}:$PATH"
    ''
    + ''
      root="$(cd "$(dirname "''${BASH_SOURCE[0]}")/.." && pwd)"
      exec ${sub}/bin/sub --name ${cmd} --absolute "$root/opt/${pname}" -- "$@"
    '';
  };

  zshCompletion = writeTextFile {
    name = "_${cmd}";
    destination = "/share/zsh/site-functions/_${cmd}";
    text = ''
      #compdef ${cmd}

      _${cmd}() {
        local -a completions
        if (( ''${#words} == 2 )); then
          completions=(''${(@f)$(${cmd} --completions)})
        else
          completions=(''${(@f)$(${cmd} --completions ''${words[@]:1:-1})})
        fi
        _describe 'command' completions
      }

      compdef _${cmd} ${cmd}
    '';
  };

  bashCompletion = writeTextFile {
    name = cmd;
    destination = "/share/bash-completion/completions/${cmd}";
    text = ''
      _${cmd}() {
        local cur
        cur="''${COMP_WORDS[COMP_CWORD]}"
        COMPREPLY=( $(compgen -W "$(${cmd} --completions)" -- "$cur") )
      }
      complete -F _${cmd} ${cmd}
    '';
  };
in
stdenv.mkDerivation (
  args
  // {
    pname = pname;
    version = args.version or "0.0.0";

    buildPhase = "true";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/opt/${pname}

      install -Dm755 ${entryScript}/bin/${cmd} $out/bin/${cmd}

      if [ -d libexec ]; then
        mkdir -p $out/opt/${pname}/libexec
        cp -a libexec/. $out/opt/${pname}/libexec/
      fi

      if [ -d lib ]; then
        mkdir -p $out/opt/${pname}/lib
        cp -a lib/. $out/opt/${pname}/lib/
      fi

      install -Dm644 ${zshCompletion}/share/zsh/site-functions/_${cmd} \
        $out/share/zsh/site-functions/_${cmd}
      install -Dm644 ${bashCompletion}/share/bash-completion/completions/${cmd} \
        $out/share/bash-completion/completions/${cmd}

      runHook postInstall
    '';
  }
)
