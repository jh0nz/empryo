{
  description = "Empryo — graph-powered AI coding agent (terminal + desktop)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
      sources = builtins.fromJSON (builtins.readFile ./nix/sources.json);
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          # Empryo is distributed under a non-free license.
          config.allowUnfree = true;
        };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          empryo = pkgs.callPackage ./nix/cli.nix { inherit sources; };
          empryo-desktop = pkgs.callPackage ./nix/desktop.nix { inherit sources; };
          default = self.packages.${system}.empryo;
        }
      );

      overlays.default = final: _prev: {
        empryo = final.callPackage ./nix/cli.nix { inherit sources; };
        empryo-desktop = final.callPackage ./nix/desktop.nix { inherit sources; };
      };

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.empryo}/bin/empryo";
        };
        desktop = {
          type = "app";
          program = "${self.packages.${system}.empryo-desktop}/bin/empryo-desktop";
        };
      });

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          # `nix develop` -> run nix/update.sh by hand
          default = pkgs.mkShell {
            packages = with pkgs; [
              curl
              jq
              openssl
            ];
          };
        }
      );

      formatter = forAllSystems (system: (pkgsFor system).nixfmt);
    };
}
