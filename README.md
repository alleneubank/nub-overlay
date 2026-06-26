# nub Nix Flake Overlay

This repository provides a Nix flake overlay for [nub](https://nubjs.com), a fast TypeScript-first runtime and pnpm-compatible package manager for Node.

The package downloads nub's official prebuilt release tarballs. It does not build nub from source, wrap the binary, or replace nub's release layout.

## Why This Exists

nub's release tarballs contain `bin/` and `runtime/` directories as siblings. The `nub` executable resolves its runtime by canonicalizing the real executable path and walking up to `runtime/preload.mjs`, so the Nix derivation installs the tree exactly as shipped:

- `bin/nub`
- `bin/nubx`
- `runtime/`

Using `makeWrapper`, symlinked entrypoints, or a source build can pass `nub --version` while failing real TypeScript workloads.

## Usage

Add the overlay to a flake:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nub-overlay.url = "github:0xbigboss/nub-overlay";
    nub-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, nub-overlay, ... }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      overlays = [nub-overlay.overlays.default];
    };
  in {
    devShells.${system}.default = pkgs.mkShell {
      nativeBuildInputs = [
        pkgs.nub
      ];
    };
  };
}
```

Run directly:

```sh
nix run github:0xbigboss/nub-overlay# -- --version
nix develop github:0xbigboss/nub-overlay
nix build github:0xbigboss/nub-overlay#nub
```

## Outputs

- `packages.<system>.nub`
- `packages.<system>.default`
- `apps.<system>.nub`
- `apps.<system>.nubx`
- `apps.<system>.default`
- `devShells.<system>.default`
- `overlays.default`, which adds `pkgs.nub` and `pkgs.nubPackages`

Supported systems:

- `x86_64-linux`
- `aarch64-linux`
- `x86_64-darwin`
- `aarch64-darwin`

## Updating

Update to the latest release:

```sh
./update
```

Update a specific version:

```sh
./update 0.2.3
```

Select a recorded version when building:

```sh
NUB_VERSION=0.2.3 nix build --impure .#nub
```

Verify recorded hashes:

```sh
./verify-hashes.sh
```
