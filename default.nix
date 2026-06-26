{
  pkgs ? import <nixpkgs> {},
  system ? builtins.currentSystem,
  nubVersion ? null,
}: let
  inherit (pkgs) lib;
  sources = builtins.fromJSON (lib.strings.fileContents ./sources.json);

  envVersion = builtins.getEnv "NUB_VERSION";
  selectedVersion =
    if nubVersion != null
    then nubVersion
    else if envVersion != ""
    then envVersion
    else "latest";

  versionData =
    if builtins.hasAttr selectedVersion sources
    then sources.${selectedVersion}
    else throw "nub version '${selectedVersion}' not found in sources.json";

  platformData =
    versionData.platforms.${system}
    or (throw "unsupported system for nub ${versionData.version}: ${system}");

  nubArchive = pkgs.fetchurl {
    inherit (platformData) url sha256;
  };

  nub = pkgs.stdenv.mkDerivation {
    pname = "nub";
    inherit (versionData) version;

    src = nubArchive;

    # The release tarball expands directly to bin/ and runtime/ at the top
    # level. nub resolves runtime/preload.mjs relative to the real executable.
    sourceRoot = ".";

    nativeBuildInputs = lib.optionals pkgs.stdenv.isLinux [
      pkgs.autoPatchelfHook
    ];
    buildInputs = lib.optionals pkgs.stdenv.isLinux [
      pkgs.stdenv.cc.cc.lib
    ];

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r bin "$out/bin"
      cp -r runtime "$out/runtime"
      chmod +x "$out/bin/nub" "$out/bin/nubx"
      runHook postInstall
    '';

    meta = with lib; {
      description = "Fast TypeScript-first runtime and pnpm-compatible package manager for Node";
      homepage = "https://nubjs.com";
      downloadPage = "https://github.com/nubjs/nub/releases";
      license = licenses.mit;
      mainProgram = "nub";
      platforms = builtins.attrNames versionData.platforms;
      sourceProvenance = [sourceTypes.binaryNativeCode];
    };
  };
in {
  inherit nub;
  default = nub;
}
