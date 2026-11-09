{
  self,
  system,
  pkgs,
  ...
}:
{

  system.primaryUser = "shar";

  # Required so Home Manager can resolve the user it manages.
  # `uid` is intentionally omitted: nix-darwin only needs it to create users
  # (we don't list `shar` in users.knownUsers), and Home Manager probes it
  # with tryEval, leaving home.uid unset so its UID check stays portable.
  users.users.shar.home = "/Users/shar";

  homebrew = {
    enable = true;
    brews = [
      "opencode"
    ];
    casks = [
      "kitty"
      "syncplay"
      "discord"
      "excalidrawz"
      "vlc"
      "cloudflare-warp"
      "gimp"
      "obsidian"
      "citrix-workspace"
      "chromium"
      "keka"
      "qbittorrent"
      "librewolf"
      "scroll-reverser"
    ];
    taps = [
      "homebrew/homebrew-core"
      "homebrew/homebrew-cask"
    ];
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };
  };

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [
  ];

  nix.settings.experimental-features = "nix-command flakes";

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = system;
}
