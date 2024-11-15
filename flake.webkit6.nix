{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Basic development tools
    pkg-config
    cargo
    rustc
    deno
    
    # WebKit2GTK 6.0 and dependencies
    webkitgtk_6_0
    gtk3
    cairo
    glib
    atk
    pango
    gdk-pixbuf
    libsoup_3
    
    # Additional build dependencies
    cmake
    ninja
    python3
    wrapGAppsHook
    
    # System libraries
    libayatana-appindicator
    librsvg
    dbus
    
    # SSL and compression
    openssl
    zlib
    bzip2
  ];

  shellHook = ''
    export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath [
      pkgs.webkitgtk_6_0
      pkgs.gtk3
      pkgs.cairo
      pkgs.glib
      pkgs.atk
      pkgs.pango
      pkgs.gdk-pixbuf
      pkgs.libsoup_3
    ]}:$LD_LIBRARY_PATH
    
    # Set PKG_CONFIG_PATH for build tools
    export PKG_CONFIG_PATH="${pkgs.webkit2gtk}/lib/pkgconfig:${pkgs.gtk3}/lib/pkgconfig:$PKG_CONFIG_PATH"
    
    # Set environment variables for WebKit2GTK
    export GDK_PIXBUF_MODULE_FILE="${pkgs.gdk-pixbuf}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"
    export WEBKIT_DISABLE_COMPOSITING_MODE=1
  '';

  # Add development-specific environment variables
  RUST_BACKTRACE = 1;
  RUST_LOG = "debug";
}
