{
  pkgs,
  ...
}:
let
  jsonFormat = pkgs.formats.json { };

  settings = {
    permissions = {
      allow = [
        "Shell(ls)"
        "Shell(uv)"
        "Shell(git status)"
        "Shell(git diff)"
      ];
      deny = [ ];
    };
    version = 1;
    editor = {
      vimMode = false;
    };
    model = {
      modelId = "composer-2-fast";
      displayModelId = "composer-2-fast";
      displayName = "Composer 2 Fast";
      displayNameShort = "Composer 2 Fast";
      aliases = [ ];
    };
    hasChangedDefaultModel = true;
    privacyCache = {
      ghostMode = false;
      privacyMode = 3;
      updatedAt = 1763647036545;
    };
    network = {
      useHttp1ForAgent = false;
    };
  };
in
{
  # Cursor CLI configuration (prettified)
  xdg.configFile."cursor/cli-config.json" = {
    source = jsonFormat.generate "cli-config.json" settings;
    force = true;
  };
}
