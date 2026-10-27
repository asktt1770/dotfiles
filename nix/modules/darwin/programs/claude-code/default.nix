# Fork-only Claude Code additions, kept out of the upstream-tracked home module
# so that module stays identical to upstream.
_:
let
  personal = import ../../../../../personal.nix;
in
{
  home-manager.users.${personal.username} =
    { pkgs, lib, ... }:
    {
      # The CLI behind the fork-only `focus` and `unfocus` skills.
      home.packages = [
        (pkgs.writeShellScriptBin "claude-focus" ''
          exec ${lib.getExe pkgs.nushell} ${./focus.nu} "$@"
        '')
      ];
    };
}
