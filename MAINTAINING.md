# Maintaining nub-overlay

## Release Updates

Run the update script from the repository root:

```sh
./update
```

The script reads the GitHub release metadata for `nubjs/nub`, prefetches the four supported official tarballs with `nix store prefetch-file --hash-type sha256`, and updates `sources.json`.

To update a specific release:

```sh
./update 0.2.3
```

## Verification

After updating:

```sh
./verify-hashes.sh
nix flake check
nix run .# -- --version
```

On Linux, `nix flake check` also builds nub with `autoPatchelfHook` and verifies that `nub --version` matches the packaged version.

## Packaging Constraint

Keep the install layout aligned with nub's official release tarball:

```text
$out/bin/
$out/runtime/
```

The set of executables under `bin/` varies by release: tarballs up to 0.6.0 ship
both `nub` and `nubx`, while 0.7.0 and later ship `nub` alone. `installPhase`
therefore marks whatever `bin/` contains executable instead of naming files.

Do not wrap or symlink the entrypoint. nub resolves its runtime from the real executable path, so wrapper-based packages can pass version checks while failing TypeScript execution.
