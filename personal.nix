# Personal configuration — the single source of truth for user/machine-specific
# values. Upstream (ryoppippi/dotfiles) does NOT have this file, so syncing
# upstream never conflicts here. Keep all personalisation in this file (and the
# modules that read it) rather than editing upstream-tracked files directly.
{
  # Identity
  username = "asktt1770";
  githubId = "75629350"; # used for the GitHub noreply commit email

  homebrew = {
    # NOTE the asymmetry below: `extraCasks` is ADDITIVE (appended to upstream's
    # casks), while `masApps` is a FULL REPLACEMENT (mkForce). Adding to one is
    # not the same operation as adding to the other.

    # Casks ADDED on top of upstream's list (nix-darwin merges by list
    # concatenation, so these are appended to whatever upstream ships).
    extraCasks = [
      "brave-browser"
      "tailscale"
      "telegram"
    ];

    # Mac App Store apps — applied with lib.mkForce, i.e. this list FULLY
    # replaces upstream's masApps. Add entries here to install more; upstream's
    # own masApps additions are intentionally NOT inherited (full curation).
    masApps = {
      "Actions" = 1586435171;
      "Amphetamine" = 937984704;
      "Keynote" = 409183694;
      "Kindle" = 302584613;
      "LINE" = 539883307;
      "Pages" = 409201541;
      "Slack" = 803453959;
      "Spark" = 1176895641;
      "The Unarchiver" = 425424353;
      "WhatsApp" = 310633997;
    };
  };
}
