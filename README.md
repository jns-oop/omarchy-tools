# omarchy-tools

Small, dependency-light tools for [Omarchy](https://omarchy.org). Each one is a
single executable script with its own `install.sh`, so any Omarchy machine can be
set up the same way in a few commands. `theme-duotone` and `cursor-picker` are
portable — paths come from `XDG_*`/`$HOME` and the cursor themes are fetched at
install time — while `battery-charge-limit` is deliberately wired to my
ThinkPad T14's `BAT0` and the `wheel` group.

## Personal use, no support

These are scripts I wrote for my own machines and publish only so I can put them
back after a reinstall. They are not a product: there is no support, no roadmap
and no promise that they keep working across Omarchy updates. Read them before
running them — they touch your dotfiles, your icon themes and, for the battery
tool, a udev rule under `/etc`. Fork and adapt freely; issues and pull requests
may go unanswered.

| Tool | What it does |
| --- | --- |
| [theme-duotone](theme-duotone/) | Recolours `~/Pictures/omarchy.png` in two colours from the current theme and drops it in that theme's background folder. |
| [cursor-picker](cursor-picker/) | TUI to browse, preview, apply and pin an installed cursor theme. |
| [battery-charge-limit](battery-charge-limit/) | Toggles my ThinkPad T14's battery charge threshold between 80% and 100%, password-free via udev. |

## Requirements

Omarchy 4.x on Arch, since the tools call the `omarchy-*` helpers. On top of a
base install:

| Need | For |
| --- | --- |
| `imagemagick`, `gum` | theme-duotone |
| `fzf` | cursor-picker |
| Material Bibata themes | cursor-picker's accent-matched setup; `cursor-picker/bibata/install.sh` downloads them |
| `curl`, `jq`, `python3` | that Bibata installer only |

battery-charge-limit is written for this machine: it expects `BAT0` under
`/sys/class/power_supply` with a `charge_control_end_threshold` attribute, a
`wheel` group, and root for the udev rule. On another laptop it needs editing.

## Install

```sh
git clone <this repository's URL> omarchy-tools
cd omarchy-tools

sudo pacman -S --needed imagemagick gum fzf jq python3

./theme-duotone/install.sh          # also restores ~/Pictures/omarchy.png
./cursor-picker/install.sh
./cursor-picker/bibata/install.sh   # 56 cursor themes + accent matching, ~170 MB
./battery-charge-limit/install.sh   # my ThinkPad T14 only: adds a udev rule (sudo)
```

Only want one? Run that directory's `install.sh`: it checks the tool's
dependencies, copies it to `~/.local/bin`, and prints the matching keybinding.
All of them are idempotent and accept `--bin-dir DIR`. The cursor setup is two
steps — `cursor-picker/install.sh` installs only the picker, `bibata/install.sh`
adds the themes, the swatch table, the theme-set hook and the login re-apply.
Nothing writes outside your home except the battery udev rule in
`/etc/udev/rules.d`, which the battery installer skips with `--no-udev`.

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
                       omarchy.png        (reference source, to ~/Pictures)
cursor-picker/         cursor-picker      install.sh   README.md
                       bibata/            accent-matched cursor setup
battery-charge-limit/   battery-charge-limit
                      99-battery-charge-limit.rules
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
