#!/bin/bash
# Material Bibata Cursor: user-level installer for Omarchy.
#
# Upstream: https://github.com/SakibShahariar/material-bibata-cursor
# Source of install: the official v1.5.0 release archives (Xcursor + Hyprcursor
# + SVG assets), not the AUR and not a source build. Themes go to
# ~/.local/share/icons because that is the path libhyprcursor 0.1.13 scans and
# XCURSOR_PATH already covers it; no sudo and no Hyprland config involved.
#
# Every accent family upstream ships is installed (dark and light), so an
# unusual accent still has a close neighbour instead of a merely approximate
# one. Classic is skipped: it is not an accent colour and has no light variant.
# Xcursor bitmaps are trimmed to 24/48 px; everything else is upstream.
#
# This also installs the control plane from this directory: pick.py (accent
# matching), xcursor_prune.py (bitmap trimming), the theme-set hook, the
# login-time re-apply and boot-check.sh. Re-run to update or repair. See NOTICE
# for the uninstall steps.
set -euo pipefail

here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

VERSION=1.5.0
BASE="https://github.com/SakibShahariar/material-bibata-cursor/releases/download/v${VERSION}"
THEMES_JSON="https://raw.githubusercontent.com/SakibShahariar/material-bibata-cursor/master/themes.json"
DARK_SHA=8a0cfddd60787c65a078ce494b5708c1d68f3e576118fde0701949edb40cba04
LIGHT_SHA=db8e41025be52abd211de6485cb12b411058f7de811216bc0f495c7b04a1364b

CONF="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/bibata-cursor"
ICONS="${XDG_DATA_HOME:-$HOME/.local/share}/icons"
HOOK="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/hooks/theme-set.d/20-bibata-cursor"
AUTOSTART="${XDG_CONFIG_HOME:-$HOME/.config}/autostart/bibata-cursor.desktop"
SIZES="24,48"
no_icons=0

usage() {
  cat <<'EOF'
Usage: install.sh [--no-icons]

  --no-icons   skip the theme download; only install the helpers, hook and
               login re-apply, with the swatch table from this directory

Installs the Material Bibata cursor themes into ~/.local/share/icons and the
accent-matching helpers into ~/.config/omarchy/bibata-cursor, including the
Omarchy theme-set hook and the login-time re-apply. No root, no Hyprland config.
Re-run to update or repair.
EOF
}

while (( $# )); do
  case "$1" in
    --no-icons) no_icons=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'install.sh: unknown option %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

# All 28 accent families from upstream themes.json (Classic excluded, see above).
FAMILIES=(
  Ice-Blue Sky-Blue Deep-Blue Soft-Blue Teal Mint Seafoam
  Sage Lime Moss Peach Apricot Sunset Blush Salmon Pink-Pastel Pink-Rose
  Lilac Violet Sand Beige Brown Cloud Grey Slate Noir Midnight Charcoal
)

mkdir -p "$ICONS" "$CONF"

if (( no_icons )); then
  echo "==> Skipping themes (--no-icons); using the swatch table from ${here}"
  # Re-running from the installed copy would install the table onto itself.
  [[ $here/colors.tsv -ef $CONF/colors.tsv ]] || install -Dm644 "$here/colors.tsv" "$CONF/colors.tsv"
else
  for tool in curl jq python3; do
    command -v "$tool" >/dev/null || { echo "$tool is required" >&2; exit 1; }
  done

  WORK=$(mktemp -d)
  trap 'rm -rf "$WORK"' EXIT
  mkdir -p "$WORK/stage"

  echo "==> Downloading Material Bibata ${VERSION}"
  curl -fsSL --retry 2 -o "$WORK/dark.tar.gz" "$BASE/bibata-material-dark-v${VERSION}.tar.gz"
  curl -fsSL --retry 2 -o "$WORK/light.tar.gz" "$BASE/bibata-material-light-v${VERSION}.tar.gz"
  curl -fsSL --retry 2 -o "$WORK/themes.json" "$THEMES_JSON"

  echo "==> Verifying release checksums"
  printf '%s  %s\n' "$DARK_SHA" "$WORK/dark.tar.gz" | sha256sum -c --quiet -
  printf '%s  %s\n' "$LIGHT_SHA" "$WORK/light.tar.gz" | sha256sum -c --quiet -

  echo "==> Building the accent table from upstream themes.json"
  : >"$WORK/colors.tsv"
  for family in "${FAMILIES[@]}"; do
    for pair in "dark:$family" "light:${family}-Light"; do
      mode=${pair%%:*}
      key=${pair#*:}
      hex=$(jq -r --arg key "$key" '.[$key].primary // empty' "$WORK/themes.json")
      [[ -n $hex ]] || { echo "themes.json has no entry for $key" >&2; exit 1; }
      printf '%s\t%s\t%s\n' "$family" "$mode" "$hex" >>"$WORK/colors.tsv"
    done
  done
  install -m 644 "$WORK/colors.tsv" "$CONF/colors.tsv"

  echo "==> Extracting ${#FAMILIES[@]} families (dark and light)"
  dark_members=()
  light_members=()
  for family in "${FAMILIES[@]}"; do
    dark_members+=("bibata-material-dark-v${VERSION}/Bibata-Material-${family}")
    light_members+=("bibata-material-light-v${VERSION}/Bibata-Material-${family}-Light")
  done
  tar xzf "$WORK/dark.tar.gz" -C "$WORK/stage" --strip-components=1 "${dark_members[@]}"
  tar xzf "$WORK/light.tar.gz" -C "$WORK/stage" --strip-components=1 "${light_members[@]}"

  echo "==> Trimming Xcursor bitmaps to ${SIZES} px"
  for directory in "$WORK"/stage/Bibata-Material-*; do
    [[ -d $directory ]] || continue
    # SVG cursors are only read by GNOME 51+ / Plasma 6.2+; Hyprland and GTK here
    # use hyprcursors/ and cursors/.
    rm -rf "$directory/cursors_scalable"
    python3 "$here/xcursor_prune.py" prune "$directory/cursors" --sizes "$SIZES"
    python3 "$here/xcursor_prune.py" verify "$directory/cursors" --sizes "$SIZES"
  done

  echo "==> Installing into ${ICONS}"
  installed=0
  for directory in "$WORK"/stage/Bibata-Material-*; do
    [[ -d $directory ]] || continue
    name=$(basename "$directory")
    rm -rf "${ICONS:?}/$name"
    mv "$directory" "$ICONS/$name"
    chmod -R a+rX "$ICONS/$name"
    installed=$((installed + 1))
  done
fi

echo "==> Installing the helpers into ${CONF}"
for file in install.sh pick.py xcursor_prune.py boot-check.sh login-apply.sh \
            20-bibata-cursor NOTICE; do
  # Re-running from the installed copy must not install a file onto itself.
  [[ $here/$file -ef $CONF/$file ]] && continue
  case "$file" in
    NOTICE) install -Dm644 "$here/$file" "$CONF/$file" ;;
    *) install -Dm755 "$here/$file" "$CONF/$file" ;;
  esac
done

echo "==> Installing the theme-set hook"
install -Dm755 "$CONF/20-bibata-cursor" "$HOOK"

echo "==> Installing the login-time re-apply"
mkdir -p "$(dirname "$AUTOSTART")"
cat >"$AUTOSTART" <<EOF
[Desktop Entry]
Type=Application
Name=Material Bibata cursor check
Comment=Re-apply the accent-matched cursor after login if the boot restore missed it
Exec=$CONF/login-apply.sh
Terminal=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

echo
if (( no_icons )); then
  echo "Themes left untouched (--no-icons)."
else
  echo "Installed ${installed} themes:"
  du -sh "$ICONS"/Bibata-Material-* | sort -k2
  echo "Total: $(du -shc "$ICONS"/Bibata-Material-* | tail -1 | cut -f1)"
fi
cat <<EOF

Installed:
  $CONF      helpers, swatch table, NOTICE
  $HOOK  theme-set hook
  $AUTOSTART  login-time re-apply

The cursor follows each Omarchy theme's accent from the next theme switch, and
the login re-apply guarantees the end state after a reboot. Verify a session with:

  $CONF/boot-check.sh

A selection made with cursor-picker pins the cursor in manual-lock; the hook
then leaves it alone. "Follow theme accent" in the picker removes the pin.
No file here is read by Hyprland's config parser, so nothing can cause a config
error. See $CONF/NOTICE for the uninstall steps.
EOF
