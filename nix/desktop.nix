{
  lib,
  fetchurl,
  appimageTools,
  stdenv,
  sources,
}:

let
  system = stdenv.hostPlatform.system;
  inherit (sources) version;
  arch =
    {
      x86_64-linux = "x86_64";
      aarch64-linux = "arm64";
    }
    .${system} or (throw "empryo-desktop: unsupported system ${system}");

  pname = "empryo-desktop";
  src = fetchurl {
    url = "https://dl.empryo.com/v${version}/Empryo-${version}-linux-${arch}.AppImage";
    hash = sources.desktop.${system};
  };
  extracted = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    # Reuse the desktop entry and icons shipped inside the AppImage.
    for f in ${extracted}/*.desktop; do
      install -Dm644 "$f" "$out/share/applications/$(basename "$f")"
    done
    if [ -d ${extracted}/usr/share/icons ]; then
      mkdir -p $out/share
      cp -r ${extracted}/usr/share/icons $out/share/
    fi
    sed -i -E 's|^Exec=[^ ]+|Exec=${pname}|' $out/share/applications/*.desktop
  '';

  meta = {
    description = "Empryo desktop app: live map of a repository with an AI coding agent";
    homepage = "https://empryo.com";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = pname;
  };
}
