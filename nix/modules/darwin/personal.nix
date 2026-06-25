# Personal nix-darwin module: applies the homebrew personalisation declared in
# the repo-root personal.nix on top of the upstream-tracked system.nix. Keeping
# this separate means system.nix stays identical to upstream (no merge conflicts
# on the frequently-churning app lists).
{ lib, ... }:
let
  personal = import ../../../personal.nix;
in
{
  # Appended to upstream's casks (list options merge by concatenation).
  homebrew.casks = personal.homebrew.extraCasks;

  # Full override of upstream's masApps (see personal.nix for rationale).
  homebrew.masApps = lib.mkForce personal.homebrew.masApps;

  # Disable Spotlight indexing on the Data volume. Personal preference:
  # Raycast covers app-launch + clipboard, and file search goes unused,
  # so the FS metadata index (mds_stores, ~1GB resident) is pure overhead.
  # Runs as root on every switch; idempotent. Revert: `mdutil -i on`.
  system.activationScripts.postActivation.text = ''
    /usr/bin/mdutil -i off /System/Volumes/Data || true
  '';
}
