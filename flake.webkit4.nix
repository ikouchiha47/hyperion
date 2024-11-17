{
  description = "Development environment for Tauri with WebKitGTK 4.1";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-darwin" ] (system: let
    pkgs = import nixpkgs { inherit system; };
  in {
    devShell = pkgs.mkShell {
      buildInputs = with pkgs; [
        # Rust toolchain
        rustc
        cargo
        pkg-config
        
        deno
        bun
        
        webkitgtk_4_1
        gtk3
        libsoup
        
        glib
        cairo
        pango
        gdk-pixbuf
        atk
        
        # SSL and development
        openssl
        openssl.dev
        
        # Additional dependencies
        libiconv
        dbus
        librsvg
        libayatana-appindicator
      ];

      shellHook = ''
        export PATH=$PATH:$HOME/.cargo/bin
        export PKG_CONFIG_PATH="${pkgs.webkitgtk_4_1}/lib/pkgconfig:${pkgs.gtk3}/lib/pkgconfig:$PKG_CONFIG_PATH"
        export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [
          pkgs.webkitgtk_4_1
          pkgs.gtk3
          pkgs.glib
          pkgs.cairo
          pkgs.pango
          pkgs.gdk-pixbuf
          pkgs.atk
          pkgs.libsoup
        ]}:$LD_LIBRARY_PATH"
      '';
    };
  });
}

