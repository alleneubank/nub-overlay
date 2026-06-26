{
  description = "Nix flake overlay for nub official binary releases.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Used for shell.nix
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }: let
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    outputs = flake-utils.lib.eachSystem systems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      envVersion = builtins.getEnv "NUB_VERSION";
      selectedVersion =
        if envVersion != ""
        then envVersion
        else null;
      nubPkgs = import ./default.nix {
        inherit pkgs system;
        nubVersion = selectedVersion;
      };
    in rec {
      packages = nubPkgs;

      apps = {
        nub = flake-utils.lib.mkApp {
          drv = packages.nub;
          name = "nub";
        };
        nubx = flake-utils.lib.mkApp {
          drv = packages.nub;
          name = "nubx";
        };
        default = apps.nub;
      };

      checks.version = pkgs.runCommand "nub-version-check" {nativeBuildInputs = [packages.nub];} ''
        test "$(nub --version)" = "v${packages.nub.version}"
        touch "$out"
      '';

      formatter = pkgs.alejandra;

      devShells.default = pkgs.mkShell {
        nativeBuildInputs = [
          packages.nub
          pkgs.jq
        ];
      };

      devShell = self.devShells.${system}.default;
    });
  in
    outputs
    // {
      overlays.default = final: prev: {
        nubPackages = outputs.packages.${prev.system};
        nub = outputs.packages.${prev.system}.nub;
      };
    };
}
