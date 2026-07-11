_final: prev: {
  # claude-code-usage-bar (PyPI: claude-statusbar). CLI `cs` renders a Claude Code
  # statusLine that reads the status JSON from stdin. Used as the statusLine command.
  claude-statusbar = prev.python3Packages.buildPythonApplication rec {
    pname = "claude-statusbar";
    version = "3.27.0";

    pyproject = true;

    src = prev.fetchPypi {
      # PyPI serves the sdist with an underscore (claude_statusbar-*.tar.gz),
      # while the project/package name uses a hyphen.
      pname = "claude_statusbar";
      inherit version;
      hash = "sha256-XNKErfnGxJhSVzZDY2QB0ZN3wjL+eFs4pNfplSyQrpM=";
    };

    build-system = [ prev.python3Packages.setuptools ];

    # Pure stdlib at runtime; the only declared dependency (claude-monitor) is an
    # optional `full` extra which we deliberately omit.
    dependencies = [ ];

    # Nix owns this install: the store is read-only and settings.json is generated
    # declaratively. Disable the daily background self-upgrade (pip/uv) that `cs`
    # would otherwise spawn from the render path. Use --set-default so it can still
    # be overridden per-shell. (The once-a-day settings.json self-heal is not gated
    # by any env var, but it writes to ~/.claude/settings.json, which Claude Code
    # does not read here since CLAUDE_CONFIG_DIR points at ~/.config/claude, so it
    # cannot clobber the Nix-managed settings.)
    makeWrapperArgs = [ "--set-default CLAUDE_STATUSBAR_NO_UPDATE 1" ];

    # No test suite wired for the packaged sdist; import check is enough.
    doCheck = false;
    pythonImportsCheck = [ "claude_statusbar" ];

    meta = {
      description = "Claude Code usage/status bar (cs)";
      homepage = "https://github.com/leeguooooo/claude-code-usage-bar";
      license = prev.lib.licenses.mit;
      maintainers = [ ];
      mainProgram = "cs";
    };
  };
}
