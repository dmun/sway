{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  # Reuse the package definition (wlroots-nightly + all of sway's deps) so the
  # dev shell and the system config can't drift apart.
  inputsFrom = [ (import ./package.nix { inherit pkgs; }) ];

  # Nix injects -D_FORTIFY_SOURCE, but meson's default buildtype compiles at
  # -O0, and glibc then #warns that fortify needs optimization -- which -Werror
  # turns into a hard error. Drop the fortify hardening so debug builds work.
  # (Disabling "fortify" disables "fortify3" too.)
  hardeningDisable = [ "fortify" ];

  shellHook = ''
    echo "wlroots: $(pkg-config --modversion wlroots-0.21 2>/dev/null || echo 'NOT FOUND')"
  '';
}
