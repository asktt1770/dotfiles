# Layers fork-only Claude Code hooks over the settings.json written by the
# upstream-tracked home module, so that module stays identical to upstream.
# Its settings are a `let` binding rather than an option, so they cannot be
# merged at evaluation time; instead a second activation step edits the live
# file right after upstream's. It also ships `claude-focus`, the CLI behind the
# fork-only `focus` and `unfocus` skills.
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
      focusGoal = pkgs.writeShellScriptBin "claude-focus-goal" ''
        exec ${lib.getExe pkgs.nushell} ${./focus-goal.nu}
      '';

      # Run by the `focus` and `unfocus` skills, which are installed whether or
      # not the guard is on, so this ships unconditionally.
      focusCli = pkgs.writeShellScriptBin "claude-focus" ''
        exec ${lib.getExe pkgs.nushell} ${./focus.nu} "$@"
      '';

      inherit (personal.claude) focusGuard;

      # The profile path never changes between generations, unlike a store
      # path, so the activation below can find and replace its own entry.
      hooks = {
        UserPromptSubmit = [
          {
            hooks = [
              {
                type = "command";
                command = "${config.home.profileDirectory}/bin/claude-focus-goal";
              }
            ];
          }
        ];
      };

      hooksJson = (pkgs.formats.json { }).generate "claude-personal-hooks.json" hooks;
      jq = lib.getExe pkgs.jq;
    in
    {
      home.packages = [ focusCli ] ++ lib.optional focusGuard focusGoal;

      home.activation.writePersonalClaudeHooks =
        lib.hm.dag.entryBetween [ "validateClaudeSettings" ] [ "writeClaudeSettings" ]
          ''
            SETTINGS_FILE="${config.xdg.configHome}/claude/settings.json"
            TEMP_FILE="$(mktemp "${config.xdg.configHome}/claude/.settings.json.XXXXXX")"
            # Per hook event: drop entries equal to ours, then append ours only
            # while enabled. That keeps upstream's entries for the same event,
            # never duplicates ours across switches, and removes ours once
            # disabled.
            if ! ${jq} --slurp --argjson enabled ${lib.boolToString focusGuard} '
              .[1] as $ours
              | .[0]
              | reduce ($ours | to_entries[]) as $event (.;
                  .hooks[$event.key] = (
                    ((.hooks[$event.key] // []) - $event.value)
                    + (if $enabled then $event.value else [] end)
                  ))
            ' "$SETTINGS_FILE" ${hooksJson} > "$TEMP_FILE"; then
              rm -f "$TEMP_FILE"
              exit 1
            fi
            mv "$TEMP_FILE" "$SETTINGS_FILE"
            chmod 644 "$SETTINGS_FILE"
          '';
    };
}
