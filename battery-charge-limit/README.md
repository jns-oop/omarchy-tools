# battery-charge-limit

Toggle a laptop's battery charge threshold between 80% and 100% from a single
command, with a desktop notification. Built for Omarchy, where it is bound to
`SUPER + B`.

The battery is found by its `charge_control_end_threshold` attribute, so `BAT0`,
`BAT1`, `CMB0` and friends all work with no configuration. `BATTERY=` picks one
explicitly on a machine with several, and `CHARGE_LIMIT` changes the 80% default.

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
./install.sh --dry-run       # print the rule that would be installed
```

The installer detects the battery and generates
`/etc/udev/rules.d/99-battery-charge-limit.rules` from
[`99-battery-charge-limit.rules.in`](99-battery-charge-limit.rules.in). The rule
does two things for that battery:

- sets `charge_control_end_threshold` to `80` at boot,
- gives an admin group write access to that attribute, so the toggle needs no
  password. The group is the first of `wheel`, `sudo`, `admin` that you are in,
  falling back to your primary group.

The installer reloads udev and applies the group permissions immediately but
does **not** re-fire the rule's `80` action, so installing does not change the
limit you are currently using.

If the script cannot write the attribute it re-runs itself through
`pkexec --user root`.

## Requirements

- A battery exposing `charge_control_end_threshold` under
  `/sys/class/power_supply`. Many ThinkPads and some other laptops have it;
  plenty of machines do not, and the installer says so and stops before the
  udev step.
- `omarchy-notification-send` for notifications (optional; failures ignored).

## Files it touches

- `~/.local/bin/battery-charge-limit`
- `/etc/udev/rules.d/99-battery-charge-limit.rules`
- the detected battery's `charge_control_end_threshold` when toggling

## Uninstall

```sh
sudo rm /etc/udev/rules.d/99-battery-charge-limit.rules ~/.local/bin/battery-charge-limit
sudo udevadm control --reload-rules
```
