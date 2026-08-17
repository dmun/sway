{
  pkgs ? import <nixpkgs> { },

  # Defaults to this working tree, so `nix-build`/`nix-shell` here Just Work.
  # From a flake, pass the locked source instead: `src = inputs.sway-src;`
  #
  # builtins.path (rather than a bare ./.) keeps multi-hundred-MB build output
  # out of the nix store, and works even when the tree is dirty.
  src ? builtins.path {
    path = ./.;
    name = "sway-source";
    filter =
      path: type:
      let
        base = baseNameOf path;
      in
      base != ".git" && base != "build" && base != "build-nix" && base != "result";
  },
}:

let
  lib = pkgs.lib;

  # sway master needs wlroots-0.21, which is not released yet -- nixpkgs only
  # ships up to wlroots_0_20. Build wlroots from git instead.
  #
  # To bump: set `rev` to the commit you want, set `hash` to lib.fakeHash, build,
  # and paste the correct hash from the resulting error message.
  wlroots-nightly = pkgs.wlroots_0_20.overrideAttrs (final: prev: {
    # majorMinor of this is "0.21", which is what makes nixpkgs expect a
    # wlroots-0.21.pc -- matching what sway's meson.build looks for.
    version = "0.21.0-dev-unstable-2026-08-17";
    __intentionallyOverridingVersion = true;

    src = pkgs.fetchFromGitLab {
      domain = "gitlab.freedesktop.org";
      owner = "wlroots";
      repo = "wlroots";
      rev = "012ca825e326ba3ec9dc5c2a0c81f08851405563";
      hash = "sha256-eq0pBV9W2raEZT83QJpXQy76TL3j5eZLWBdBXVxAl1g=";
    };

    # If a wlroots commit introduces a new dependency, add it here rather than
    # replacing the 0.20 list:
    # buildInputs = prev.buildInputs ++ [ pkgs.some-new-dep ];
  });
in
# Keep nixpkgs' sway-unwrapped -- its patches (load-configuration-from-etc,
# fix-paths for swaybg) all still apply to 1.13-dev -- and swap only the source
# and wlroots.
(pkgs.sway-unwrapped.override {
  wlroots_0_20 = wlroots-nightly;
}).overrideAttrs
  (old: {
    version = "1.13-dev-focus-tab";
    __intentionallyOverridingVersion = true;
    inherit src;
  })
