{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  ripgrep,
  fd,
  lazygit,
  neovim,
  git,
  sources,
}:

let
  system = stdenv.hostPlatform.system;
  inherit (sources) version;
  platform =
    {
      x86_64-linux = "linux-x64";
      aarch64-linux = "linux-arm64";
    }
    .${system} or (throw "empryo: unsupported system ${system}");
in
stdenv.mkDerivation {
  pname = "empryo";
  inherit version;

  src = fetchurl {
    url = "https://dl.empryo.com/v${version}/empryo-${version}-${platform}.tar.gz";
    hash = sources.cli.${system};
  };

  sourceRoot = "empryo-${version}-${platform}";

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = [ stdenv.cc.cc.lib ];

  # The binary is a `bun build --compile` executable: the JS payload is
  # appended to the ELF, and stripping would destroy it.
  dontStrip = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # Empryo looks for `deps/` (wasm grammars, native libs) next to its own
    # executable, so keep the upstream layout under libexec and wrap it.
    mkdir -p $out/libexec/empryo $out/bin
    cp -r empryo deps $out/libexec/empryo/
    # Bundled rg/fd/lazygit are replaced by nixpkgs builds on PATH.
    rm -f $out/libexec/empryo/deps/{rg,fd,lazygit}

    install -Dm644 LICENSE $out/share/licenses/empryo/LICENSE
    install -Dm644 THIRD_PARTY_LICENSES.md $out/share/licenses/empryo/THIRD_PARTY_LICENSES.md

    makeWrapper $out/libexec/empryo/empryo $out/bin/empryo \
      --set-default EMPRYO_WASM_DIR $out/libexec/empryo/deps/wasm \
      --suffix PATH : ${
        lib.makeBinPath [
          ripgrep
          fd
          lazygit
          neovim
          git
        ]
      }
    ln -s empryo $out/bin/em

    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Graph-powered, codebase-aware AI coding agent for the terminal";
    homepage = "https://empryo.com";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "empryo";
  };
}
