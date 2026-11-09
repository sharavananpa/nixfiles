# Using this repo on multiple devices

> Status: **design document**. This describes how to extend the repo to multiple
> machines (macOS + Linux, different architectures). It has not been implemented
> yet — the current flake still targets a single `aarch64-darwin` machine.

## Goal

One repository that configures:

- an Apple Silicon MacBook (`aarch64-darwin`)
- a Linux machine (`x86_64-linux`), either NixOS or an existing distribution

Each machine gets its own flake output and its own `system`, while sharing as
much configuration as possible.

## Core principle

**Home Manager is the portable layer. nix-darwin and NixOS are the per-OS layers.**

- Shared user configuration (packages, shell, editor, CLI tools) lives in
  Home Manager modules and is imported by every device.
- System configuration (bootloader, users, services, Homebrew) lives in a
  per-host module and is specific to the OS.
- Architecture is chosen **per output**, never as one global `system` variable.

A single flake can expose all of these at once:

| Device | Flake output | Rebuild command |
|---|---|---|
| macOS | `darwinConfigurations.<host>` | `sudo darwin-rebuild switch --flake .#<host>` |
| NixOS | `nixosConfigurations.<host>` | `sudo nixos-rebuild switch --flake .#<host>` |
| Other Linux | `homeConfigurations."<user>@<host>"` | `home-manager switch --flake .#<user>@<host>` |

## Target structure

```
flake.nix
modules/
  home/
    default.nix      # imports common + the platform module
    common.nix       # cross-platform Home Manager config
    darwin.nix       # macOS-only Home Manager bits
    linux.nix        # Linux-only Home Manager bits
hosts/
  macbook/
    default.nix      # nix-darwin system config + Homebrew
  linuxbox/
    configuration.nix
    hardware-configuration.nix   # generated on the target machine
```

This is a refactor of the current layout:

- `home.nix` → `modules/home/{default,common,darwin,linux}.nix`
- `darwin-config.nix` → `hosts/macbook/default.nix`

## Flake skeleton

```nix
outputs = inputs@{
  self, nixpkgs, nix-darwin, home-manager, nix-homebrew,
  homebrew-core, homebrew-cask, ...
}:
let
  username = "shar";
  homeModule = ./modules/home/default.nix;

  mkHome = { system }:
    home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${system};
      extraSpecialArgs = { inherit username; };
      modules = [ homeModule ];
    };
in
{
  # Apple Silicon macOS
  darwinConfigurations."macbook" = nix-darwin.lib.darwinSystem {
    specialArgs = { inherit self username; system = "aarch64-darwin"; };
    modules = [
      ./hosts/macbook/default.nix
      nix-homebrew.darwinModules.nix-homebrew
      home-manager.darwinModules.home-manager
      {
        home-manager.extraSpecialArgs = { inherit username; };
        home-manager.users.${username} = homeModule;
      }
    ];
  };

  # NixOS x86_64 (full system management)
  nixosConfigurations."linuxbox" = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit username; };
    modules = [
      ./hosts/linuxbox/configuration.nix
      home-manager.nixosModules.home-manager
      {
        home-manager.extraSpecialArgs = { inherit username; };
        home-manager.users.${username} = homeModule;
      }
    ];
  };

  # Non-NixOS Linux (Ubuntu/Fedora/…): Home Manager only
  homeConfigurations."${username}@linux" = mkHome { system = "x86_64-linux"; };
}
```

## Shared vs platform-specific

`modules/home/default.nix`:

```nix
{ pkgs, lib, username, ... }:
{
  imports = [ ./common.nix ]
    ++ lib.optionals pkgs.stdenv.isDarwin [ ./darwin.nix ]
    ++ lib.optionals pkgs.stdenv.isLinux  [ ./linux.nix ];

  home.username = username;
  home.homeDirectory =
    if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";
  home.stateVersion = "25.05";
}
```

Where things belong:

| Module | Contents |
|---|---|
| `modules/home/common.nix` | zsh, starship, git, delta, fzf, zoxide, kitty, neovim, ripgrep, … (all cross-platform) |
| `modules/home/darwin.nix` | macOS-only Home Manager settings |
| `modules/home/linux.nix` | Linux-only packages/settings (e.g. `feh`) |
| `hosts/macbook/default.nix` | `system.primaryUser`, `users.users`, `nix-homebrew`, `homebrew`, `nix.settings`, `nixpkgs.hostPlatform = "aarch64-darwin"` |
| `hosts/linuxbox/configuration.nix` | `boot.loader`, `fileSystems`, `users.users.${username}`, `networking.hostName`, `system.stateVersion`, `nixpkgs.hostPlatform = "x86_64-linux"` |

**Never** put `homebrew`, `system.defaults`, or `system.primaryUser` in shared
code — those are Darwin-only.

## Linux: choose a model

| Linux setup | Flake output | First/ongoing command |
|---|---|---|
| **NixOS** (full declarative system) | `nixosConfigurations.linuxbox` | `sudo nixos-rebuild switch --flake .#linuxbox` |
| **Existing distro** (Ubuntu, Fedora, …) | `homeConfigurations."shar@linux"` | `home-manager switch --flake .#shar@linux` |

Notes:

- **NixOS**: generate `hardware-configuration.nix` on the target with
  `nixos-generate-config`, and declare `users.users.${username}` — Home Manager's
  NixOS module requires the user to exist.
- **Non-NixOS Linux**: install Nix multi-user, enable flakes, then bootstrap
  Home Manager the first time with
  `nix run home-manager/master -- switch --flake .#shar@linux`.
  Only user-level configuration is managed; the OS itself is not.

## Migration plan (without breaking the Mac)

1. Work on a branch or in a worktree.
2. Extract `home.nix` into `modules/home/{default,common,darwin,linux}.nix`.
3. Move `darwin-config.nix` into `hosts/macbook/default.nix`.
4. Keep the existing output name (`macos`) at first so the Mac's command does
   not change; rename to `macbook` only when convenient.
5. Add the Linux output.
6. Validate all outputs from the Mac (evaluation is cross-platform).
7. Switch the Mac and confirm there is no regression.
8. Set up the Linux machine.

## Validating outputs

Evaluation works from any machine; **building** a host requires a matching
machine or CI runner.

```sh
# macOS system
nix eval .#darwinConfigurations.macos.config.system.build.toplevel.drvPath

# NixOS system
nix eval .#nixosConfigurations.linuxbox.config.system.build.toplevel.drvPath

# Standalone Home Manager
nix eval .#homeConfigurations."shar@linux".activationPackage.drvPath
```

For CI, run macOS jobs on a macOS runner and Linux jobs on a Linux runner;
`nix flake check` plus per-host evaluation catches most mistakes cheaply.

## Gotchas

- `home.stateVersion` can stay shared; `system.stateVersion` is **per OS**.
- If you enable `home-manager.useGlobalPkgs = true`, move
  `nixpkgs.config.allowUnfreePredicate` from the Home Manager config to the
  system config (otherwise `nixpkgs.config` is ignored or conflicts).
- Name standalone Home Manager outputs distinctly (`shar@linux`, `shar@mac`)
  so they do not collide.
- Packages that only exist on one platform must live in the matching module
  (e.g. `feh` on Linux).
- The dictionary data in `stardict/` and the dotfiles are shared as-is.
- `nixpkgs.hostPlatform` (or the `system` argument) must be set correctly for
  each host; a single global `system` is what prevents multi-arch support.
