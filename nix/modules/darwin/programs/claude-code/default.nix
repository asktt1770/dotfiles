# Fork-only Claude Code additions, kept out of the upstream-tracked home module
# so that module stays identical to upstream.
_:
let
  personal = import ../../../../../personal.nix;
in
{
  home-manager.users.${personal.username} =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      # The retired focus guard hook. Upstream merges its settings over the
      # live settings.json with jq's `*`, which never removes keys, so an entry
      # registered by an earlier switch would outlive the binary it points to.
      retiredHook = "${config.home.profileDirectory}/bin/claude-focus-goal";
      jq = lib.getExe pkgs.jq;
    in
    {
      # The CLI behind the fork-only `focus` and `unfocus` skills.
      home.packages = [
        (pkgs.writeShellScriptBin "claude-focus" ''
          exec ${lib.getExe pkgs.nushell} ${./focus.nu} "$@"
        '')
      ];

      home.activation.removeRetiredClaudeHooks =
        lib.hm.dag.entryBetween [ "validateClaudeSettings" ] [ "writeClaudeSettings" ]
          ''
            SETTINGS_FILE="${config.xdg.configHome}/claude/settings.json"
            TEMP_FILE="$(mktemp "${config.xdg.configHome}/claude/.settings.json.XXXXXX")"
            # Drop every hook entry that runs the retired command, then any
            # event left empty. Other entries, upstream's included, are kept.
            if ! ${jq} --arg retired ${lib.escapeShellArg retiredHook} '
              if .hooks then
                .hooks |= with_entries(
                  .value |= map(select(all(.hooks[]?; .command != $retired)))
                  | select(.value != [])
                )
              else . end
            ' "$SETTINGS_FILE" > "$TEMP_FILE"; then
              rm -f "$TEMP_FILE"
              exit 1
            fi
            mv "$TEMP_FILE" "$SETTINGS_FILE"
            chmod 644 "$SETTINGS_FILE"
          '';
    };
}
