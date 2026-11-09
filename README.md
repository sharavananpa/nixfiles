# nixfiles

My macOS configuration, managed declaratively with [nix-darwin](https://github.com/nix-darwin/nix-darwin), [Home Manager](https://github.com/nix-community/home-manager), and [nix-homebrew](https://github.com/zhaofengli/nix-homebrew).

A single `darwin-rebuild switch` applies the system configuration, Home Manager, and Homebrew packages.

## Layout

| Path | Purpose |
|---|---|
| `flake.nix` | Flake inputs and the `macos` darwin configuration |
| `darwin-config.nix` | System-level config: users, Homebrew, nix settings |
| `home.nix` | User-level config: packages, zsh, git, kitty, etc. |
| `dotfiles/` | Starship config, macOS defaults script, Brewfile, scripts |
| `stardict/` | Dictionary data linked into `~/.config/stardict/dic` |

## Branch

The default branch `main` is out of date. **Use `mac`** — it contains the current configuration, including the Home Manager integration.

## Fresh machine setup

> Tested on Apple Silicon with user `shar`. If your username or architecture differs, see [Customization](#customization) before running the switch.

### 1. Xcode Command Line Tools

```sh
xcode-select --install
```

### 2. Install Nix (multi-user)

Run this from an **admin** account:

```sh
sh <(curl -L https://nixos.org/nix/install)
```

Open a new terminal afterwards.

> Determinate Nix also works, but then set `nix.enable = false;` in `darwin-config.nix` so it doesn't conflict with nix-darwin's daemon management.

### 3. Enable flakes

```sh
mkdir -p ~/.config/nix
echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

### 4. Clone the repo and check out `mac`

```sh
git clone https://github.com/sharavananpa/nixfiles.git ~/nixfiles
cd ~/nixfiles
git switch mac
```

Optional — only needed for the Neovim config (an uninitialized submodule):

```sh
git submodule update --init --recursive
```

### 5. First switch

This bootstraps `darwin-rebuild` itself, installs Homebrew via `nix-homebrew`, and activates Home Manager:

```sh
sudo nix --extra-experimental-features 'nix-command flakes' \
  run github:nix-darwin/nix-darwin/master#darwin-rebuild -- \
  switch --flake .#macos
```

Expect the first run to take a while (Homebrew and the pinned taps are large).

### 6. Verify

```sh
darwin-version
readlink /run/current-system
ls -l ~/.config/starship.toml
```

## Daily usage

```sh
cd ~/nixfiles
sudo darwin-rebuild switch --flake .#macos
```

That's it — nix-darwin, Home Manager, and Homebrew are all applied in one command.

To update pinned inputs first:

```sh
nix flake update
sudo darwin-rebuild switch --flake .#macos
```

## Customization

The config is hardcoded for user `shar` and `aarch64-darwin`. If your machine differs, update these:

| File | Setting |
|---|---|
| `flake.nix` | `system = "aarch64-darwin";` → `x86_64-darwin` on Intel |
| `flake.nix` | `home-manager.users.shar` |
| `flake.nix` | `user = "shar";` (nix-homebrew) |
| `flake.nix` | `homeConfigurations."shar"` (optional standalone target) |
| `darwin-config.nix` | `system.primaryUser = "shar";` |
| `darwin-config.nix` | `users.users.shar.home = "/Users/shar";` |
| `home.nix` | `home.username` / `home.homeDirectory` |
| `home.nix` | `programs.git.settings.user.*` |

`users.users.shar` intentionally omits `uid`: nix-darwin only needs a UID for accounts it manages (via `users.knownUsers`), and Home Manager probes it with `tryEval`, so `home.uid` stays unset and the config stays portable across machines with different UIDs.

## Notes

- **Homebrew cleanup is destructive.** `homebrew.onActivation.cleanup = "zap"` removes any brew/cask not declared in `darwin-config.nix`. Don't run the switch on a machine with manually installed Homebrew apps you want to keep.
- **`home-manager` CLI is not installed** — that's intentional when Home Manager runs as a nix-darwin submodule. Use `darwin-rebuild` instead.
- **macOS defaults are not managed by the flake.** Run them manually:
  ```sh
  bash ~/nixfiles/dotfiles/scripts/macos/change-defaults.sh
  ```
- **`dotfiles/bootstrap-macos.sh.bak` is obsolete** (old Homebrew + `stow` flow); ignore it.
- The flake output is named `macos`; if you rename it, update the `--flake .#macos` commands.

## Troubleshooting

### Nix behaves strangely after a crash or dead battery

An unclean shutdown can corrupt the Nix SQLite database. Check it with:

```sh
sqlite3 "file:/nix/var/nix/db/db.sqlite?mode=ro" "PRAGMA integrity_check;"
```

- If the output is `ok`, the database is fine.
- If it reports **missing index entries**, rebuild the indexes:
  ```sh
  sudo launchctl bootout system/org.nixos.nix-daemon
  sudo sqlite3 /nix/var/nix/db/db.sqlite 'REINDEX;'
  sudo sqlite3 /nix/var/nix/db/db.sqlite 'PRAGMA integrity_check;'
  sudo launchctl bootstrap system /Library/LaunchDaemons/org.nixos.nix-daemon.plist
  ```
- If `REINDEX` fails with `UNIQUE constraint failed`, the DB has duplicate rows; restore `db.sqlite` from a backup (Time Machine) or rebuild it with `sqlite3 db '.recover'`.

After repairing the DB, verify the store paths:

```sh
sudo nix-store --verify --check-contents --repair
```

### A build fails with `cannot stat '/nix/store/...'`

A store path is registered but missing from disk (usually after an interrupted build). First make sure the database is healthy (see above), then force the path to rebuild:

```sh
nix build --rebuild /nix/store/<name>.drv
```

If more paths are affected, run `sudo nix-store --verify --check-contents --repair` (this can take a while).
