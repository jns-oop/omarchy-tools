#!/usr/bin/env bash
# Install battery-charge-limit and the udev rule that lets group wheel change
# the charge threshold without a password.
#
#   ./install.sh              # script into ~/.local/bin, rule into /etc/udev
#   ./install.sh --no-udev    # script only

set -euo pipefail

here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
bin_dir="${BIN_DIR:-$HOME/.local/bin}"
script="battery-charge-limit"
rule_name="99-battery-charge-limit.rules"
rule_dir="/etc/udev/rules.d"
with_udev=true

usage() {
  cat <<'EOF'
Usage: install.sh [--bin-dir DIR] [--no-udev]

  --bin-dir DIR   where to install the script (default: ~/.local/bin)
  --no-udev       install the script only, skip the udev rule
EOF
}

while (( $# )); do
  case "$1" in
    --bin-dir) bin_dir="${2:?--bin-dir wants a path}"; shift 2 ;;
    --no-udev) with_udev=false; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'install.sh: unknown option %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

if ! command -v udevadm >/dev/null 2>&1; then
  printf 'warning: udevadm not found; the udev rule cannot be applied here.\n' >&2
fi

install -Dm755 "$here/$script" "$bin_dir/$script"
printf 'installed %s\n' "$bin_dir/$script"

attr=/sys/class/power_supply/BAT0/charge_control_end_threshold

if ! $with_udev; then
  printf 'skipped the udev rule; the toggle will prompt for a password each time.\n' >&2
elif [[ ! -e $attr ]]; then
  printf 'warning: %s does not exist on this machine — no charge threshold support.\n' "$attr" >&2
  printf '         Installed the script only; nothing changed at the kernel level.\n' >&2
else
  if (( EUID == 0 )); then
    run() { "$@"; }
  elif command -v sudo >/dev/null 2>&1; then
    run() { sudo "$@"; }
  else
    printf 'warning: need root to install %s/%s; copy it yourself and reload udev.\n' \
      "$rule_dir" "$rule_name" >&2
    run() { return 1; }
  fi

  if run install -Dm644 "$here/$rule_name" "$rule_dir/$rule_name"; then
    run udevadm control --reload-rules || true
    # Apply the group write access now without re-running the rule's
    # "threshold=80" action, so the current limit stays where it is.
    run chgrp wheel "$attr" 2>/dev/null || true
    run chmod 0664 "$attr" 2>/dev/null || true
    printf 'installed %s\n' "$rule_dir/$rule_name"
  fi
fi

cat <<EOF

Status:      $script status
Toggle:      $script toggle        (or: on | off)

Optional keybinding, in ~/.config/hypr/bindings.lua:

  o.bind("SUPER + B", "Charge limit", "$bin_dir/battery-charge-limit toggle")
EOF
