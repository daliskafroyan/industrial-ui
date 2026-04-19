{
  description = "Nix development environment for the industrial-ui monorepo";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          lib = pkgs.lib;
        in {
          default = pkgs.mkShell {
            packages =
              with pkgs;
              [
                bun
                nodejs_22
                git
                openssl
                pkg-config
                python3
              ]
              ++ lib.optionals stdenv.isLinux [
                stdenv.cc.cc.lib
              ];

            LD_LIBRARY_PATH = lib.optionalString pkgs.stdenv.isLinux (
              lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]
            );

            shellHook = ''
              if [ -n "''${XDG_CACHE_HOME:-}" ]; then
                bun_cache_root="$XDG_CACHE_HOME"
              elif [ "$(uname -s)" = "Darwin" ]; then
                bun_cache_root="$HOME/Library/Caches"
              else
                bun_cache_root="$HOME/.cache"
              fi

              export BUN_INSTALL_CACHE_DIR="$bun_cache_root/industrial-ui/bun-install-cache"

              cat <<'EOF'
Nix dev shell ready for industrial-ui.

First run:
  bun install

Common commands:
  bun run dev
  bun run dev --filter=ui
  bun run dev --filter=www
  bun run dev --filter=origin

If you want the local apps to link to each other, set up the .env.local files described in README.md.
EOF
            '';
          };
        }
      );

      apps = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          mkWorkspaceApp =
            name: command:
            let
              runner = pkgs.writeShellApplication {
                inherit name;
                runtimeInputs = [
                  pkgs.bun
                  pkgs.git
                  pkgs.nodejs_22
                ];
                text = ''
                  repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
                  cd "$repo_root"

                  if [ ! -f package.json ]; then
                    echo "Run this command from the industrial-ui repository." >&2
                    exit 1
                  fi

                  if [ ! -d node_modules ]; then
                    echo "Installing workspace dependencies with bun..."
                    bun install --frozen-lockfile
                  fi

                  exec bun ${command} "$@"
                '';
              };
            in {
              type = "app";
              program = "${runner}/bin/${name}";
            };
        in {
          default = mkWorkspaceApp "industrial-ui-dev" "run dev";
          dev = mkWorkspaceApp "industrial-ui-dev" "run dev";
          ui = mkWorkspaceApp "industrial-ui-ui-dev" "run dev --filter=ui";
          www = mkWorkspaceApp "industrial-ui-www-dev" "run dev --filter=www";
          origin = mkWorkspaceApp "industrial-ui-origin-dev" "run dev --filter=origin";
        }
      );
    };
}
