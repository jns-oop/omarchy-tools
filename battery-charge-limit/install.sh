#!/usr/bin/env bash
# Install battery-charge-limit and a udev rule that lets an admin group change
# the charge threshold without a password.
#
#   ./install.sh              # script into ~/.local/bin, rule into /etc/udev
#   ./install.sh --no-udev    # script only
#   ./install.sh --dry-run    # show what would be installed, change nothing

set -euo pipefail

here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
bin_dir="${BIN_DIR:-$HOME/.local/bin}"
script="battery-charge-limit"
rule_name="99-battery-charge-limit.rules"
rule_template="$here/${rule_name}.in"
rule_dir="${RULE_DIR:-/etc/udev/rules.d}"
with_udev=true
dry_run=false

usage() {
  cat <<'EOF'
Usage: install.sh [--bin-dir DIR] [--no-udev] [--dry-run]

  --bin-dir DIR   where to install the script (default: ~/.local/bin)
  --no-udev       install the script only, skip the udev rule
  --dry-run       print what would be installed and exit
EOF
}

while (( $# )); do
  case "$1" in
    --bin-dir) bin_dir="${2:?--bin-dir wants a path}"; shift 2 ;;
    --no-udev) with_udev=false; shift ;;
    --dry-run) dry_run=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'install.sh: unknown option %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

if ! command -v udevadm >/dev/null 2>&1; then
  printf 'warning: udevadm not found; the udev rule cannot be applied here.\n' >&2
fi

if $dry_run; then
  printf 'would install %s/%s\n' "$bin_dir" "$script"
else
  install -Dm755 "$here/$script" "$bin_dir/$script"
  printf 'installed %s\n' "$bin_dir/$script"
fi

# Any power supply exposing the threshold attribute works; the kernel name is
# not assumed. BATTERY=... overrides the detection.
detect_battery() {
  local dir
  for dir in /sys/class/power_supply/*; do
    [[ -e $dir/charge_control_end_threshold ]] || continue
    printf '%s\n' "$dir"
    return 0
  done
  return 1
}

# The first admin group this user belongs to gets write access, so neither the
# battery name nor a distribution-specific group name is hardcoded.
detect_group() {
  local group
  for group in wheel sudo admin; do
    getent group "$group" >/dev/null 2>&1 || continue
    if id -nG | tr ' ' '\n' | grep -qx "$group"; then
      printf '%s\n' "$group"
      return 0
    fi
  done
  id -gn
}

battery="$(detect_battery || true)"
battery="${battery%/}"

if ! $with_udev; then
  printf 'skipped the udev rule; the toggle will ask for a password each time.\n' >&2
elif [[ -z $battery ]]; then
  printf 'warning: no power supply with charge_control_end_threshold found.\n' >&2
  printf '         This machine cannot limit charging; installed the script only.\n' >&2
else
  kernel_name="${battery##*/}"
  group="$(detect_group)"
  attr="$battery/charge_control_end_threshold"

  rendered="$(mktemp)"
  trap 'rm -f "$rendered"' EXIT
  sed -e "s|@BATTERY@|$kernel_name|g" -e "s|@GROUP@|$group|g" "$rule_template" >"$rendered"

  if $dry_run; then
    printf '\nwould install %s/%s:\n\n' "$rule_dir" "$rule_name"
    sed 's/^/  /' "$rendered"
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

    if run install -Dm644 "$rendered" "$rule_dir/$rule_name"; then
      run udevadm control --reload-rules || true
      # Apply the group write access now without re-running the rule's
      # "limit at boot" action, so the current limit stays where it is.
      run chgrp "$group" "$attr" 2>/dev/null || true
      run chmod 0664 "$attr" 2>/dev/null || true
      printf 'installed %s (battery %s, group %s)\n' \
        "$rule_dir/$rule_name" "$kernel_name" "$group"
    fi
  fi
fi

cat <<EOF

Status:      $script status
Toggle:      $script toggle        (or: on | off)

Optional keybinding, in ~/.config/hypr/bindings.lua:

  o.bind("SUPER + B", "Charge limit", "$bin_dir/battery-charge-limit toggle")
EOF
