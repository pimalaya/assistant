{
  description = "Pimalaya Assistant runner";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAll = f: nixpkgs.lib.genAttrs systems (system: f (pkgs system));
      pkgs =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg: nixpkgs.lib.getName pkg == "claude-code";
        };
      runtime =
        p: with p; [
          claude-code
          coreutils
          curl
          gh
          git
          gnused
          jq
          openssl
          pass
          ripgrep
        ];
    in
    {
      packages = forAll (p: {
        default = p.writeShellApplication {
          name = "pimalaya-assistant";
          runtimeInputs = runtime p;
          runtimeEnv.ASSISTANT_DIR = "${
            p.lib.fileset.toSource {
              root = ./.;
              fileset = p.lib.fileset.unions [ ./prompt.md ./schema.json ];
            }
          }";
          text = builtins.readFile ./run.sh;
        };
      });

      nixosModules.default = import ./module.nix self;

      devShells = forAll (p: {
        default = p.mkShell { packages = runtime p ++ [ p.shellcheck ]; };
      });
    };
}
