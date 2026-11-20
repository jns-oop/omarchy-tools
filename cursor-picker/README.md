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

- A cursor theme to pick from. **Any** theme on `XCURSOR_PATH` works — the
  picker only reads directories that contain `cursors/` or a Hyprcursor
  `manifest.hl`.

  This setup is built around
  [Material Bibata](https://github.com/SakibShahariar/material-bibata-cursor) —
  the `Bibata-Material-*` families (dark and light) built from
  [Bibata_Cursor](https://github.com/ful1e5/Bibata_Cursor) — installed **per
  user** into `~/.local/share/icons`: libhyprcursor only scans the user icon
  dir, and `XCURSOR_PATH` already covers it.

  ```sh
  ./bibata/install.sh        # themes, helpers and the accent matching
  ```

  The `manual-lock` pin, the `colors.tsv` swatches and the theme-set hook assume
  that setup; without it the picker still lists, applies and persists any theme.

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
