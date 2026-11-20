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

Requires `fzf`:

```sh
sudo pacman -S --needed fzf
```

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
