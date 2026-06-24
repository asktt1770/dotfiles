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
}
