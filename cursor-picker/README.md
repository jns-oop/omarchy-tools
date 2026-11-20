# cursor-picker

A TUI for picking an installed Xcursor/Hyprcursor theme. It applies the
focused theme to the running session as you move through the list, and on
confirm persists the choice for the next login.

Picking a theme pins it: an entry is written to
`~/.config/omarchy/bibata-cursor/manual-lock` so a theme-set hook stops
replacing the cursor on every Omarchy theme switch. The first row of the
picker — **Follow theme accent** — removes that pin again.

## Install

```sh
./install.sh                 # -> ~/.local/bin/cursor-picker
```

## Requirements

- `fzf` for the picker itself:

  ```sh
  sudo pacman -S --needed fzf
  ```

- A cursor theme to pick from. This setup uses
  [bibata-material-cursors](https://github.com/SakibShahariar/material-bibata-cursor)
  — the `Bibata-Material-*` families (dark and light) built from
  [Bibata_Cursor](https://github.com/ful1e5/Bibata_Cursor) — installed **per
  user** from its GitHub releases. They go to `~/.local/share/icons`, not
  `/usr/share/icons`: libhyprcursor only scans the user icon dir, and
  `XCURSOR_PATH` already covers it.

  ```sh
  cd /tmp
  v=1.5.0
  base=https://github.com/SakibShahariar/material-bibata-cursor/releases/download/v$v
  curl -LO "$base/bibata-material-dark-v$v.tar.gz"
  curl -LO "$base/bibata-material-light-v$v.tar.gz"
  tar xzf "bibata-material-dark-v$v.tar.gz"
  tar xzf "bibata-material-light-v$v.tar.gz"
  mkdir -p ~/.local/share/icons
  mv "bibata-material-dark-v$v"/Bibata-Material-* ~/.local/share/icons/
  mv "bibata-material-light-v$v"/Bibata-Material-* ~/.local/share/icons/
  ```

  Any theme on `XCURSOR_PATH` works with the picker, but the
  `manual-lock` pin path and the optional `colors.tsv` swatches are built
  around Bibata Material. The control plane — accent matching, the theme-set
  hook, the login re-apply and bitmap trimming — ships in [`bibata/`](bibata/).

`hyprctl`, `gsettings` and `dbus-update-activation-environment` are used when
present; without them the picker still persists the choice for next login.

## Use

```sh
cursor-picker                       # interactive
cursor-picker --list                # list detected themes
cursor-picker --theme Bibata-Material-Grey-Light --size 32
cursor-picker --theme Bibata-Material-Grey-Light --dry-run
```

| Key | Action |
| --- | --- |
| `↑` / `↓` | move (applies live) |
| `ctrl-s` | cycle cursor size: 24 → 32 → 48 |
| `enter` | apply, persist and pin |
| `esc` | cancel and restore the cursor you started with |

Flags: `--theme NAME`, `--size N`, `--no-pin` (remember but keep following the
theme accent), `--dry-run`, `--list`, `--help`.

## Files it touches

- `~/.config/uwsm/env.d/60-cursor` — `XCURSOR_THEME`, `XCURSOR_SIZE`,
  `HYPRCURSOR_THEME`, `HYPRCURSOR_SIZE` for the next login.
- `~/.config/omarchy/bibata-cursor/manual-lock` — the pin.
- Theme discovery uses `XCURSOR_PATH`, defaulting to
  `~/.local/share/icons:~/.icons:/usr/share/icons:/usr/share/pixmaps`.
- Nothing outside your home directory is modified.

## Optional swatches

If `~/.config/omarchy/bibata-cursor/colors.tsv` exists (tab separated
`family⇥dark|light⇥#rrggbb`), each Bibata row shows its accent colour as a
marker. Without the file, rows fall back to a dim marker.

## Accent-matched setup

[`bibata/install.sh`](bibata/) installs the rest of the setup: the Material
Bibata themes, `pick.py`, the Omarchy theme-set hook that recolours the cursor
to the theme accent, the login-time re-apply and `boot-check.sh`.

```sh
./bibata/install.sh              # themes + helpers
./bibata/install.sh --no-icons   # helpers only
```

See [`bibata/README.md`](bibata/README.md) for what lands where and how the
hook, the pin and the `60-cursor` login file interact.
