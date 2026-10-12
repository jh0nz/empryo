# Nix packaging

Packages the prebuilt Empryo binaries from `dl.empryo.com` (the v3 source is private).

- `empryo` — terminal app (`empryo`, `em`)
- `empryo-desktop` — desktop app (AppImage wrapped with `appimageTools`)

## Usage

```nix
# flake.nix
inputs.empryo.url = "github:jh0nz/empryo";

# configuration.nix
environment.systemPackages = [
  inputs.empryo.packages.${pkgs.system}.empryo
  inputs.empryo.packages.${pkgs.system}.empryo-desktop
];
```

Or use `inputs.empryo.overlays.default` to get `pkgs.empryo` / `pkgs.empryo-desktop`.
Try without installing: `nix run github:jh0nz/empryo` / `nix run github:jh0nz/empryo#desktop`.

## Updating

`.github/workflows/update-nix.yml` runs daily (and via *Run workflow*). It runs
`nix/update.sh`, which reads `dl.empryo.com/latest.txt`, verifies the RSA signature of
`SHA256SUMS.txt` against `nix/empryo-sign.pub`, rewrites `nix/sources.json`, builds, and pushes.
Then refresh your system with `nix flake update empryo`.
