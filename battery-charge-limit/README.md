# battery-charge-limit

Toggle my ThinkPad T14's battery charge threshold between 80% and 100% from a
single command, with a desktop notification. Built for Omarchy, where it is
bound to `SUPER + B`.

> **Hardcoded for my ThinkPad T14.** `BAT0`, the `wheel` group and the 80% limit
> appear literally in the script, the udev rule and `install.sh`. That is
> deliberate: this copy exists to reproduce one machine, not to be portable.
> On a different laptop, change those values first — the battery name under
> `/sys/class/power_supply` and the group you belong to.

```sh
battery-charge-limit          # toggle 80% <-> 100%
battery-charge-limit on       # stop charging at 80%
battery-charge-limit off      # charge to 100%
battery-charge-limit status   # limit, capacity and charging state
```

## Install

```sh
./install.sh                 # script + udev rule (asks for sudo)
./install.sh --no-udev       # script only; the toggle then uses pkexec
```

The udev rule does two things for `BAT0`:

- sets `charge_control_end_threshold` to `80` at boot,
- gives group `wheel` write access to that attribute, so the toggle needs no
  password.

The installer reloads udev and applies the group permissions immediately but
does **not** re-fire the rule's `80` action, so installing does not change the
limit you are currently using.

If the script cannot write the attribute it re-runs itself through
`pkexec --user root`.

## Requirements

- A battery exposed as `/sys/class/power_supply/BAT0` with
  `charge_control_end_threshold`. Most ThinkPads have it; many other laptops
  do not, and some use `BAT1`.
- `omarchy-notification-send` for notifications (optional; failures ignored).

## Files it touches

- `~/.local/bin/battery-charge-limit`
- `/etc/udev/rules.d/99-battery-charge-limit.rules`
- `/sys/class/power_supply/BAT0/charge_control_end_threshold` when toggling

## Uninstall

```sh
sudo rm /etc/udev/rules.d/99-battery-charge-limit.rules ~/.local/bin/battery-charge-limit
sudo udevadm control --reload-rules
```
