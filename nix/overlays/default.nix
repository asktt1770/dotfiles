final: prev:
let
  # Import all overlay files in this directory
  overlayFiles = [
    ./claude-code.nix
    # GitHub CLI extensions
    ./gh-user-stars.nix
    ./gh-triage.nix
    # Small Go/Rust CLI tools not in nixpkgs
    ./git-now.nix
    ./bluetooth-connector.nix
    ./roots.nix
    ./audio-priority-bar.nix
    # Claude Code statusLine (PyPI: claude-statusbar, CLI `cs`)
    ./claude-statusbar.nix
  ];

  # Apply each overlay and merge results
  applyOverlays = builtins.foldl' (acc: overlay: acc // (import overlay final prev)) { } overlayFiles;
in
applyOverlays
