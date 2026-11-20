# omarchy-tools

Small, dependency-light tools I use on top of [Omarchy](https://omarchy.org).
Each one is a single executable script with its own `install.sh`, so a fresh
Omarchy install can be brought back to this setup in a few commands.

| Tool | What it does |
| --- | --- |
| [theme-duotone](theme-duotone/) | Recolours `~/Pictures/omarchy.png` in two colours from the current theme and drops it in that theme's background folder. |
| [cursor-picker](cursor-picker/) | TUI to browse, preview, apply and pin an installed cursor theme. |
| [battery-charge-limit](battery-charge-limit/) | Toggles a ThinkPad charge threshold between 80% and 100%, password-free via udev. |

## Requirements

Omarchy 4.x on Arch (the scripts use `omarchy-*` helpers and `pacman`), plus
`bash` and `coreutils`. Per-tool extras are listed in each README:
`imagemagick` + `gum`, `fzf`, and nothing extra respectively.

## Install

Clone once, then run the installer for the tools you want. The installers are
idempotent, take `--bin-dir DIR` (default `~/.local/bin`), and never write
outside your home directory except the battery udev rule in
`/etc/udev/rules.d`.

```sh
git clone https://github.com/jns-oop/omarchy-tools.git
cd omarchy-tools

./theme-duotone/install.sh
./cursor-picker/install.sh
./battery-charge-limit/install.sh
```

## Keybindings

Add to `~/.config/hypr/bindings.lua`:

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
cursor-picker/         cursor-picker      install.sh   README.md
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
