# Personal nix-darwin module: applies the homebrew personalisation declared in
# the repo-root personal.nix on top of the upstream-tracked system.nix. Keeping
# this separate means system.nix stays identical to upstream (no merge conflicts
# on the frequently-churning app lists).
{ lib, ... }:
let
  personal = import ../../../personal.nix;
in
{
  imports = [
    ./programs/claude-code
    ./programs/cmux
    ./programs/neru
  ];

  # Appended to upstream's taps and casks (list options merge by concatenation).
  homebrew.taps = personal.homebrew.extraTaps;
  homebrew.casks = personal.homebrew.extraCasks;

  # Full override of upstream's masApps (see personal.nix for rationale).
  homebrew.masApps = lib.mkForce personal.homebrew.masApps;
}
