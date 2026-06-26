#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f sources.json ]]; then
  echo "error: sources.json not found" >&2
  exit 1
fi

for cmd in jq nix; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: required command '$cmd' not found" >&2
    exit 1
  fi
done

versions=$(jq -r 'keys[]' sources.json)

for version in $versions; do
  echo "checking version: $version"
  platforms=$(jq -r --arg version "$version" '.[$version].platforms | keys[]' sources.json)

  for platform in $platforms; do
    url=$(jq -r --arg version "$version" --arg platform "$platform" '.[$version].platforms[$platform].url' sources.json)
    expected=$(jq -r --arg version "$version" --arg platform "$platform" '.[$version].platforms[$platform].sha256' sources.json)

    echo "  $platform"
    actual=$(nix store prefetch-file --hash-type sha256 --json "$url" | jq -r '.hash')

    if [[ "$actual" != "$expected" ]]; then
      echo "hash mismatch for $version $platform" >&2
      echo "  expected: $expected" >&2
      echo "  actual:   $actual" >&2
      exit 1
    fi
  done
done

echo "all hashes match"
