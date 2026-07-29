{ pkgs, ... }:
let
  # hunk's versionCheckHook runs `hunk --version` during installCheckPhase.
  # The binary is a `bun build --compile` bundle whose --version path reaches
  # out to the network; the darwin build sandbox permits that, but the Linux
  # sandbox blocks it, so the check finds no version string and the whole
  # home-manager build fails on CI's Linux runners. Keep the check on darwin
  # (the platform actually used) and skip only the install check on Linux.
  hunk =
    if pkgs.stdenv.hostPlatform.isLinux then
      pkgs.llm-agents.hunk.overrideAttrs (_: {
        doInstallCheck = false;
      })
    else
      pkgs.llm-agents.hunk;
in
{
  home.packages = [ hunk ];
}
