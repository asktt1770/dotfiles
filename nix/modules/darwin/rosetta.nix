{ ... }:
{
  system.activationScripts.postActivation.text = ''
    # Install Rosetta 2 for x86_64 binary translation (e.g. terminal-notifier)
    if ! /usr/bin/pgrep -q oahd 2>/dev/null; then
      echo "Installing Rosetta 2..."
      softwareupdate --install-rosetta --agree-to-license || true
    fi
  '';
}
