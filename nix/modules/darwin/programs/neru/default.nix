# Neru itself is the `y3owk1n/tap/neru` Homebrew cask (see personal.nix), so
# Neru.app keeps a stable path in /Applications and its Accessibility and
# Screen Recording grants survive updates. This module only supplies the config
# and the login agent, and is imported from personal.nix so that no
# upstream-tracked file has to change.
_:
let
  inherit (import ../../../../../personal.nix) username;
in
{
  home-manager.users.${username} = {
    # [hotkeys] entries merge over Neru's defaults rather than replacing them,
    # so the defaults that collide with native shortcuts are disabled by name:
    # an event tap sees a key before the focused app does, and Cmd+Shift+C/B/G/S
    # are already Save As, Find Previous and friends in many apps.
    xdg.configFile."neru/config.toml".text = ''
      [hotkeys]
      "Primary+Shift+Space" = "hints --action left_click"
      "Primary+Shift+G" = "__disabled__"
      "Primary+Shift+C" = "__disabled__"
      "Primary+Shift+B" = "__disabled__"
      "Primary+Shift+S" = "__disabled__"
    '';

    # Declared here instead of via `neru services install`, which writes an
    # unmanaged plist under ~/Library/LaunchAgents.
    launchd.agents.neru = {
      enable = true;
      config = {
        ProgramArguments = [
          "/Applications/Neru.app/Contents/MacOS/neru"
          "launch"
        ];
        ProcessType = "Interactive";
        RunAtLoad = true;
        # Restart after a crash, but not after quitting from the menu bar.
        KeepAlive.SuccessfulExit = false;
      };
    };
  };
}
