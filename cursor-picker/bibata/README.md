# bibata/

The accent-matched cursor setup behind `cursor-picker`: it makes a Material
Bibata theme follow the active Omarchy theme's accent colour, and keeps that
choice alive across a reboot.

```sh
./install.sh              # themes + helpers (downloads ~170 MB once)
./install.sh --no-icons   # helpers only, when the themes are already there
```

`install.sh` verifies the release SHA-256, trims the Xcursor bitmaps to 24/48 px,
installs the themes into `~/.local/share/icons/Bibata-Material-*`, and places the
files below. Needs `curl`, `jq` and `python3` for a themed install; no root, no
Hyprland config.

| File | Installed as | Role |
| --- | --- | --- |
| `install.sh` | `~/.config/omarchy/bibata-cursor/install.sh` | this installer, re-runnable |
| `pick.py` | same dir | nearest Bibata family for an accent, by hue in LCh |
| `xcursor_prune.py` | same dir | trim and libXcursor-verify the bitmaps |
| `colors.tsv` | same dir | `family⇥dark|light⇥#rrggbb`, regenerated on install |
| `20-bibata-cursor` | `~/.config/omarchy/hooks/theme-set.d/` | theme-set hook |
| `login-apply.sh` | same dir | login-time re-apply, run from `~/.config/autostart/bibata-cursor.desktop` |
| `boot-check.sh` | same dir | post-reboot PASS/FAIL audit |
| `NOTICE` | same dir | upstream credits, installed paths, uninstall |

## How the pieces fit

- **Hook** — on every Omarchy theme switch, matches the accent to a family in
  the theme's own mode (dark themes get dark art, light themes light art),
  applies it live via `hyprctl` and `gsettings`, and rewrites
  `~/.config/uwsm/env.d/50-bibata-cursor` for the next cold start. It exits
  immediately when `manual-lock` exists, so a manual pick is never overridden.
- **`60-cursor`** — `cursor-picker` writes this file, which sorts after
  `50-bibata-cursor`, so a pinned choice wins at login.
- **`login-apply.sh`** — waits for the compositor, records what the session
  inherited in `~/.local/state/bibata-cursor/`, runs the hook, and re-shows the
  pointer if the boot intro never restored it.
- **`boot-check.sh`** — prints a PASS/FAIL report per layer; useful once after a
  reboot, nothing depends on it.

Everything is user-level. Nothing here is read by Hyprland's config parser, so
no uninstall can leave a config error behind — removal steps are in `NOTICE`.
