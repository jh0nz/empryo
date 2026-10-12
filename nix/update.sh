#!/usr/bin/env bash
# Resolve the latest Empryo release from dl.empryo.com, verify the signed
# SHA256SUMS.txt against the pinned release key, and rewrite nix/sources.json.
# Usage: nix/update.sh [version]   (default: whatever /latest.txt points to)
set -euo pipefail

DL_BASE="https://dl.empryo.com"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

version="${1:-$(curl -fsSL "$DL_BASE/latest.txt" | tr -d '[:space:]')}"
version="${version#v}"
[[ -n "$version" ]] || { echo "could not resolve version" >&2; exit 1; }
base="$DL_BASE/v$version"

curl -fsSL "$base/SHA256SUMS.txt" -o "$tmp/SHA256SUMS.txt"
curl -fsSL "$base/SHA256SUMS.txt.sig" -o "$tmp/SHA256SUMS.txt.sig"
openssl dgst -sha256 -verify "$here/empryo-sign.pub" \
  -signature "$tmp/SHA256SUMS.txt.sig" "$tmp/SHA256SUMS.txt" >/dev/null \
  || { echo "SHA256SUMS signature verification FAILED" >&2; exit 1; }

sri() {
  local file="$1" hex
  hex="$(awk -v f="$file" '$2 == f { print $1 }' "$tmp/SHA256SUMS.txt")"
  [[ -n "$hex" ]] || { echo "no checksum for $file" >&2; exit 1; }
  nix hash convert --hash-algo sha256 --to sri "$hex"
}

jq -n \
  --arg version "$version" \
  --arg cliX64 "$(sri "empryo-$version-linux-x64.tar.gz")" \
  --arg cliArm "$(sri "empryo-$version-linux-arm64.tar.gz")" \
  --arg appX64 "$(sri "Empryo-$version-linux-x86_64.AppImage")" \
  --arg appArm "$(sri "Empryo-$version-linux-arm64.AppImage")" \
  '{
    version: $version,
    cli: { "x86_64-linux": $cliX64, "aarch64-linux": $cliArm },
    desktop: { "x86_64-linux": $appX64, "aarch64-linux": $appArm }
  }' > "$here/sources.json.new"
mv "$here/sources.json.new" "$here/sources.json"
echo "sources.json -> $version"
