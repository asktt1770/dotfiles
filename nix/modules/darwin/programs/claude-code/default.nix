# Fork-only Claude Code additions, kept out of the upstream-tracked home module
# so that module stays identical to upstream.
_:
let
  personal = import ../../../../../personal.nix;
in
{
  home-manager.users.${personal.username} =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      sessionStatus = pkgs.writeShellScriptBin "claude-session-status" ''
        exec ${lib.getExe pkgs.nushell} ${./session-status.nu} "$@"
      '';

      sessionStatusHooks = (pkgs.formats.json { }).generate "claude-session-status-hooks.json" (
        lib.mapAttrs
          (_: subcommand: [
            {
              hooks = [
                {
                  type = "command";
                  command = "${lib.getExe sessionStatus} ${subcommand}";
                }
              ];
            }
          ])
          {
            Stop = "refresh";
            UserPromptSubmit = "reset";
          }
      );
    in
    {
      home = {
        packages = [
          # The CLI behind the fork-only `focus` and `unfocus` skills.
          (pkgs.writeShellScriptBin "claude-focus" ''
            exec ${lib.getExe pkgs.nushell} ${./focus.nu} "$@"
          '')
          # The CLI behind the fork-only `done` and `sweep` skills.
          sessionStatus
        ];

        # Applied to the file rather than to the settings in the home module, so
        # that module stays identical to upstream. Entries from an older store
        # path are dropped first, and every other hook in the file is kept.
        activation.writeClaudeSessionStatusHooks =
          lib.hm.dag.entryBetween [ "validateClaudeSettings" ] [ "writeClaudeSettings" ]
            ''
              SETTINGS_FILE="${config.xdg.configHome}/claude/settings.json"
              TEMP_FILE="$(mktemp "$SETTINGS_FILE.XXXXXX")"
              if ! ${lib.getExe pkgs.jq} -s -f ${./session-status-hooks.jq} "$SETTINGS_FILE" ${sessionStatusHooks} > "$TEMP_FILE"; then
                rm -f "$TEMP_FILE"
                exit 1
              fi
              chmod 644 "$TEMP_FILE"
              mv "$TEMP_FILE" "$SETTINGS_FILE"
            '';
      };
    };
}
