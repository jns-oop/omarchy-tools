# omarchy-tools

Small, dependency-light tools for [Omarchy](https://omarchy.org). Each one is a
single executable script with its own `install.sh`, so any Omarchy machine can be
set up the same way in a few commands. Nothing here is tied to a particular
hostname, username, battery or theme: paths come from `XDG_*`/`$HOME` and the
hardware parts are detected at install time.

| Tool | What it does |
| --- | --- |
| [theme-duotone](theme-duotone/) | Recolours `~/Pictures/omarchy.png` in two colours from the current theme and drops it in that theme's background folder. |
| [cursor-picker](cursor-picker/) | TUI to browse, preview, apply and pin an installed cursor theme. |
| [battery-charge-limit](battery-charge-limit/) | Toggles a laptop's battery charge threshold between 80% and 100%, password-free via udev. |

## Requirements

Omarchy 4.x on Arch, since the tools call the `omarchy-*` helpers. On top of a
base install:

| Need | For |
| --- | --- |
| `imagemagick`, `gum` | theme-duotone |
| `fzf` | cursor-picker |
| `bibata-material-cursors` | cursor-picker's accent-matched setup — `cursor-picker/bibata/install.sh` fetches it |
| `curl`, `jq`, `python3` | that Bibata installer only |

battery-charge-limit additionally needs a battery that exposes
`charge_control_end_threshold` under `/sys/class/power_supply` (detected, not
assumed); without one its installer still installs the script and skips the
udev rule.

## Install

```sh
git clone <this repository's URL> omarchy-tools
cd omarchy-tools

sudo pacman -S --needed imagemagick gum fzf
./theme-duotone/install.sh
./cursor-picker/install.sh
./battery-charge-limit/install.sh
```

Only want one? Run that directory's `install.sh`: it checks the tool's
dependencies, copies it to `~/.local/bin`, and prints the matching keybinding.
All three are idempotent, accept `--bin-dir DIR`, and write nothing outside
your home except the battery udev rule in `/etc/udev/rules.d` (skippable with
`--no-udev`, and printable without changing anything with `--dry-run`).

## Keybindings

These are the bindings this repo uses; pick your own and keep the same commands.
Add them to `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + ALT + D", "Duotone wallpaper",
       "omarchy-launch-tui " .. os.getenv("HOME") .. "/.local/bin/theme-duotone")
o.bind("SUPER + ALT + C", "Cursor theme",
       "omarchy-launch-tui " .. os.getenv("HOME") .. "/.local/bin/cursor-picker")
o.bind("SUPER + B", "Charge limit",
       os.getenv("HOME") .. "/.local/bin/battery-charge-limit toggle")
```

On Omarchy versions that still use `~/.config/hypr/bindings.conf`, write the
same three lines in `bind = SUPER ALT, D, exec, omarchy-launch-tui ...` form.

## Repo layout

```
theme-duotone/         theme-duotone      install.sh   README.md
                       omarchy.png        (reference source image)
cursor-picker/         cursor-picker      install.sh   README.md
                       bibata/            accent-matched cursor setup
battery-charge-limit/   battery-charge-limit
                      99-battery-charge-limit.rules.in   (udev template)
                       install.sh         README.md
```

One directory per tool, script at the top of it, no build step. Nothing is
managed by a package manager, so uninstalling is a `rm` of the installed file
(each README lists the exact paths).

## Conventions

- Bash, `set -euo pipefail`, no runtime installs.
- Everything user-local goes under `~/.local/bin` or `~/.config`; the only root
  action is the battery udev rule, and it is announced and skippable.
- `install.sh` verifies dependencies and prints the matching keybinding before
  it exits.

## License

MIT — see [LICENSE](LICENSE).
