{
  description = "Nix flake for setting up a development environment with Qt6 and Rust";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-darwin" ] (system: let
    pkgs = import nixpkgs { inherit system; };
    in
    {
      default = pkgs.stdenv.mkDerivation {
          name = "hyperbase";
          buildInputs = [
            pkgs.rustc
            pkgs.cargo
            pkgs.cmake
            pkgs.ninja
            pkgs.pkg-config
            pkgs.qt6.qtbase
            pkgs.qt6.qtdeclarative
            pkgs.qt6.qttools
            pkgs.qt6.qtmultimedia
          ];
        };

      devShell = pkgs.mkShell {
        buildInputs = [
          pkgs.qt6.qtbase
          pkgs.qt6.qtdeclarative
          pkgs.qt6.qttools
          pkgs.qt6.qtmultimedia
          pkgs.rustc
          pkgs.cargo
          pkgs.cmake
          pkgs.ninja
          pkgs.pkg-config
        ];

        QT_SELECT = "6";
        shellHook = ''
          echo "Development environment with Qt6 and Rust is ready!"
          export PATH=$PATH:${pkgs.qt6.qtbase}/bin

          export QMAKE=${pkgs.qt6.qtbase}/bin/qmake
        '';
      };
    });
}

