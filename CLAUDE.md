# CLAUDE.md

This repository is a Nix flake overlay that packages nub by downloading official prebuilt release tarballs.

## Key Files

- `flake.nix`: flake outputs for packages, apps, dev shell, checks, and `overlays.default`.
- `default.nix`: nub derivation and platform selection from `sources.json`.
- `sources.json`: release URLs and SHA-256 hashes for supported platforms.
- `update`: updates `sources.json` from `nubjs/nub` GitHub releases.
- `verify-hashes.sh`: re-prefetches every recorded URL and checks hashes.

## Commands

```bash
nix flake check
nix run .# -- --version
nix build .#nub
./verify-hashes.sh
./update
```

To build a recorded non-latest version:

```bash
NUB_VERSION=0.2.3 nix build --impure .#nub
```

## Packaging Constraint

nub release tarballs expand to top-level `bin/` and `runtime/` directories. The derivation must copy both into `$out` exactly as siblings:

```text
$out/bin/nub
$out/bin/nubx
$out/runtime/
```

Do not use `makeWrapper` or a symlinked entrypoint. nub resolves `runtime/preload.mjs` relative to the canonical real executable path; wrappers can pass `nub --version` while breaking TypeScript execution.
