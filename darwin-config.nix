{
  self,
  system,
  pkgs,
  ...
}:
{

  system.primaryUser = "shar";

  homebrew = {
    enable = true;
    brews = [
    ];
    casks = [
      "kitty"
      "excalidrawz"
      "cloudflare-warp"
      "gimp"
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
