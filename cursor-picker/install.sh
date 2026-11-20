#!/usr/bin/env bash
# Install cursor-picker into ~/.local/bin (or $BIN_DIR).
#
#   ./install.sh              # install for the current user
#   ./install.sh --bin-dir ~/bin

set -euo pipefail

here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
bin_dir="${BIN_DIR:-$HOME/.local/bin}"
script="cursor-picker"

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

if ! command -v fzf >/dev/null 2>&1; then
  printf 'cursor-picker: fzf is required\n  sudo pacman -S --needed fzf\n' >&2
  exit 1
fi

# A leftover symlink would make `install` write through to its target instead
# of replacing the binary, so drop it first.
[[ -L $bin_dir/$script ]] && rm -f "$bin_dir/$script"

install -Dm755 "$here/$script" "$bin_dir/$script"

printf 'installed %s\n' "$bin_dir/$script"
cat <<EOF

List themes: $script --list
Open picker: $script

Optional keybinding, in ~/.config/hypr/bindings.lua:

  o.bind("SUPER + ALT + C", "Cursor theme",
         "omarchy-launch-tui $bin_dir/cursor-picker")
EOF

if [[ ! -f ${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/bibata-cursor/colors.tsv ]]; then
  printf '\nnote: no colors.tsv found, so rows show a plain marker instead of a colour swatch.\n' >&2
fi

icons="${XDG_DATA_HOME:-$HOME/.local/share}/icons"
if ! compgen -G "$icons/Bibata-Material-*" >/dev/null; then
  printf '\nnote: no Bibata-Material themes in %s.\n' "$icons" >&2
  printf '      cursor-picker lists any installed theme, but the accent-matched setup\n' >&2
  printf '      (swatches, theme-set hook, login re-apply) is the Bibata one:\n' >&2
  printf '        %s\n' "$here/bibata/install.sh" >&2
fi
