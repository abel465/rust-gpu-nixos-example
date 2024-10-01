{
  description = "rust-gpu-nixos-example";

  inputs = {
    fenix = {
      url = "github:nix-community/fenix/5708f08c8bcb6dd98b573a162e05cd5aa506091e";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    fenix,
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
      perSystem = {
        pkgs,
        system,
        ...
      }: let
        rustPkg = fenix.packages.${system}.latest.withComponents [
          "rust-src"
          "rustc-dev"
          "llvm-tools-preview"
          "cargo"
          "clippy"
          "rustc"
          "rustfmt"
          "rust-analyzer"
        ];
        rustPlatform = pkgs.makeRustPlatform {
          cargo = rustPkg;
          rustc = rustPkg;
        };
        shadersCompilePath = "$HOME/.cache/rust-gpu-shaders";
        sdf-builder = rustPlatform.buildRustPackage {
          pname = "rust-gpu-nixos-example";
          version = "0.0.0";
          src = ./.;
          cargoLock.lockFile = ./Cargo.lock;
          cargoLock.outputHashes = {
            "rustc_codegen_spirv-0.9.0" = "sha256-6QENP2ttWrtykfv+TUfjGrOajkN2X9cHYINauFZiup8=";
          };
          nativeBuildInputs = [pkgs.makeWrapper];
          configurePhase = ''
            export RUNNER_DIR="$out/repo/runner"
          '';
          fixupPhase = ''
            cp -r . $out/repo
            wrapProgram $out/bin/runner \
              --set LD_LIBRARY_PATH $out/lib \
              --set PATH $PATH:${nixpkgs.lib.makeBinPath [rustPkg]}
          '';
        };
      in rec {
        packages.default = pkgs.writeShellScriptBin "sdf-builder" ''
          export CARGO_TARGET_DIR="${shadersCompilePath}"
          exec -a "$0" "${sdf-builder}/bin/runner" "$@"
        '';
        apps.default = {
          type = "app";
          program = "${packages.default}/bin/sdf-builder";
        };
        devShells.default = with pkgs;
          mkShell {
            nativeBuildInputs = [rustPkg];
          };
      };
    };
}
