{ config }:
let
  inherit (config.home) username;
  inherit (import ../../../../personal.nix) githubId; # single source of truth
  email = "${githubId}+${username}@users.noreply.github.com";
in
{
  inherit username githubId email;
}
