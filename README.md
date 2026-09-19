# SubNix

Nix packaging and modules for [sub](https://github.com/juanibiapina/sub) — scripts with superpowers.

## Adding as a flake input

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sub-nix.url = "github:yueyinqiu/SubNix";
  };

  outputs = { nixpkgs, sub-nix, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # ...
    };
}
```

## Package

The `sub` binary itself:

```nix
sub-nix.packages.${system}.sub
```

Or try it directly from the CLI:

```console
$ nix shell github:yueyinqiu/SubNix#sub
```

## Lib

`makeSubCli` builds a sub CLI from a source tree containing a `libexec/` directory
(and optionally a `lib/` directory for shared code):

```nix
sub-nix.lib.${system}.makeSubCli {
  pname = "hat";
  version = "1.0.0";
  src = ./cli;                       # directory containing libexec/
  runtimeInputs = [ pkgs.jq ];       # optional: runtime deps, prepended to PATH
}
```

Parameters:

| Name | Default | Description |
| --- | --- | --- |
| `pname` | (required) | Package name |
| `version` | (required) | Package version |
| `command` | `pname` | Entry-point command name |
| `sub` | this flake's `sub` | The `sub` binary to run |
| `runtimeInputs` | `[ ]` | Runtime dependencies, prepended to `PATH` |
| `src` | (required) | Source tree containing `libexec/` |
| `meta` | `{ }` | `meta` attribute set |
| `passthru` | `{ }` | `passthru` attribute set |

The generated CLI provides:

- an entry point at `bin/<command>` running `sub --absolute <src>`
- bash completion at `share/bash-completion/completions/<command>`

> sub provides `--completions` but no official guidance on wiring it into a
> shell, so the completion here is hand-written — and only bash is covered for
> now. Contributions for other shells are welcome.

## home-manager

```nix
{
  home-manager.users.alice = { pkgs, ... }: {
    imports = [ sub-nix.homeManagerModules.sub-nix ];

    programs."sub-nix" = {
      enable = true;
      # package = sub-nix.packages.${pkgs.system}.sub;   # optional, defaults to it

      clis.hat = {
        version = "1.0.0";
        src = ./cli;                   # directory containing libexec/
        command = "hat";               # optional, defaults to the attribute name
        runtimeInputs = [ pkgs.jq ];   # optional
      };
    };
  };
}
```

## NixOS

```nix
{
  nixosConfigurations.foo = { pkgs, ... }: {
    imports = [ sub-nix.nixosModules.sub-nix ];

    programs."sub-nix" = {
      enable = true;

      clis.hat = {
        version = "1.0.0";
        src = ./cli;
      };
    };
  };
}
```

Options under `programs."sub-nix"`:

| Name | Type | Description |
| --- | --- | --- |
| `enable` | bool | Whether to enable sub-based CLIs |
| `package` | package | The `sub` package used to build the CLIs |
| `installSub` | bool | Whether to install the `sub` binary itself, defaults to `true` |
| `clis` | attrsOf submodule | CLIs to build and install |

Each CLI in `clis` accepts:

| Name | Type | Description |
| --- | --- | --- |
| `src` | path | Directory containing `libexec/` (and optionally `lib/`) |
| `version` | str | Version of this CLI |
| `command` | str | Command name, defaults to the attribute name |
| `runtimeInputs` | list of package | Runtime dependencies prepended to `PATH` |

---

All documentation and `description` fields in this repository are AI-generated.
