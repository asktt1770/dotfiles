{
  pkgs,
  config,
  dotfilesDir ? "${config.home.homeDirectory}/ghq/github.com/ryoppippi/dotfiles",
  ...
}:
let
  codexConfigDir = "${config.xdg.configHome}/codex";
  codexDotfilesDir = "${dotfilesDir}/codex";

in
{
  home = {
    # Codex package
    packages = [ pkgs.llm-agents.codex ];

    # Set CODEX_HOME environment variable (sourced via hm-session-vars.sh)
    sessionVariables = {
      CODEX_HOME = codexConfigDir;
    };

    # Codex configuration files (mutable symlinks to dotfiles)
    file = {
      "${codexConfigDir}/config.toml".source =
        config.lib.file.mkOutOfStoreSymlink "${codexDotfilesDir}/config.toml";
      "${codexConfigDir}/AGENTS.md".source =
        config.lib.file.mkOutOfStoreSymlink "${codexDotfilesDir}/AGENTS.md";
    };
  };
}
