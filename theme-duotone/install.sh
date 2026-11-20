#!/usr/bin/env bash
# Install theme-duotone into ~/.local/bin (or $BIN_DIR).
#
#   ./install.sh              # install for the current user
#   ./install.sh --bin-dir ~/bin

set -euo pipefail

here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
bin_dir="${BIN_DIR:-$HOME/.local/bin}"
script="theme-duotone"

usage() {
  cat <<'EOF'
Usage: install.sh [--bin-dir DIR]

  --bin-dir DIR   where to install the script (default: ~/.local/bin)
EOF
}

while (( $# )); do
  case "$1" in
    --bin-dir) bin_dir="${2:?--bin-dir wants a path}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'install.sh: unknown option %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

missing=()
command -v magick >/dev/null 2>&1 || missing+=(imagemagick)
command -v gum >/dev/null 2>&1 || missing+=(gum)

if (( ${#missing[@]} )); then
  printf 'theme-duotone: missing required packages: %s\n' "${missing[*]}" >&2
  printf '  sudo pacman -S --needed %s\n' "${missing[*]}" >&2
  exit 1
fi

if ! command -v omarchy-theme-bg-set >/dev/null 2>&1; then
  printf 'warning: omarchy-theme-bg-set not found — Omarchy is not installed here.\n' >&2
  printf '         The tool will render images but cannot read the theme palette.\n' >&2
fi

install -Dm755 "$here/$script" "$bin_dir/$script"

# The default --source points at ~/Pictures/omarchy.png. Restore the reference
# image only when it is missing, so a reinstall never overwrites your own.
pictures="${XDG_PICTURES_DIR:-$HOME/Pictures}"
if [[ ! -e $pictures/omarchy.png ]]; then
  install -Dm644 "$here/omarchy.png" "$pictures/omarchy.png"
  printf 'installed %s\n' "$pictures/omarchy.png"
fi

printf 'installed %s\n' "$bin_dir/$script"
cat <<EOF

Try it:      $script --help
             $script            # pick a preset, then confirm

Optional keybinding, in ~/.config/hypr/bindings.lua:

  o.bind("SUPER + ALT + D", "Duotone wallpaper",
         "omarchy-launch-tui $bin_dir/theme-duotone")
EOF
