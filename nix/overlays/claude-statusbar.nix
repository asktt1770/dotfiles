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
