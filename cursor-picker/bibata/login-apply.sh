#!/bin/bash
# Login-time safety net for the Material Bibata cursor.
#
# Started from ~/.config/autostart/bibata-cursor.desktop through the session's
# XDG autostart target, so it involves no Hyprland config. Omarchy's
# startup-cursor.lua is the normal route; this only guarantees the end state:
# re-derive the accent match from the active theme, apply it, and un-hide the
# pointer if the boot intro never restored it.
#
# It also records the theme and cursor the session inherited at login, for
# boot-check.sh. A single line of outcome goes to
# ~/.local/state/bibata-cursor/login-apply.log on every login.
set -u

CONF="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/bibata-cursor"
HOOK="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/hooks/theme-set.d/20-bibata-cursor"
ENV_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/uwsm/env.d/50-bibata-cursor"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/bibata-cursor"
DELAY="${BIBATA_CURSOR_LOGIN_DELAY:-12}"

mkdir -p "$STATE"
log="$STATE/login-apply.log"

# Autostart can race the compositor; wait for IPC before doing anything.
for _ in $(seq 1 60); do
  hyprctl version >/dev/null 2>&1 && break
  sleep 0.5
done

if ! hyprctl version >/dev/null 2>&1; then
  printf '%s skipped: Hyprland not reachable\n' "$(date -Is)" >"$log"
  exit 0
fi

# Give the boot intro time to finish before judging the pointer state.
sleep "$DELAY"

before=$(hyprctl getoption cursor:invisible 2>/dev/null | head -1)

# Record what this session inherited at login before the hook can rewrite it;
# boot-check.sh compares the fixed session variables against these.
theme_before=$(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null)
cursor_before=$(sed -n 's/^export XCURSOR_THEME=//p' "$ENV_FILE" 2>/dev/null)
printf '%s\n' "$theme_before" >"$STATE/login-theme"
printf '%s\n' "$cursor_before" >"$STATE/login-cursor"

applied=no
if [[ -x $HOOK ]]; then
  "$HOOK" >/dev/null 2>&1 && applied=yes
fi

# The intro hides the cursor and restores it when the wallpaper is ready. If it
# is still hidden now, that restore never ran: show it again and re-apply.
unhid=no
if [[ $before == "bool: true" ]]; then
  hyprctl eval 'hl.config({ cursor = { invisible = false } })' >/dev/null 2>&1
  [[ $applied == yes ]] && "$HOOK" >/dev/null 2>&1
  unhid=yes
fi

printf '%s applied=%s cursor_invisible_before=%s unhid=%s theme=%s cursor=%s\n' \
  "$(date -Is)" "$applied" "${before:-unknown}" "$unhid" \
  "${theme_before:-unknown}" "${cursor_before:-unknown}" >"$log"

exit 0
