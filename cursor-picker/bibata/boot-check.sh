#!/bin/bash
# Cold-start check for the Material Bibata cursor.
#
# Run once after a reboot, from a terminal in the new session:
#   ~/.config/omarchy/bibata-cursor/boot-check.sh
#
# XCURSOR_THEME / HYPRCURSOR_THEME are fixed when the session starts, while the
# theme can be switched afterwards. So the session variables are checked against
# the cursor login-apply.sh recorded at login, and gsettings, the env file and
# the compositor against the theme that is active now.
#
# Exits 0 when everything matches, non-zero with a FAIL line per problem.
set -u

CONF="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/bibata-cursor"
ENV_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/uwsm/env.d/50-bibata-cursor"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/bibata-cursor"
COLORS="$HOME/.local/state/omarchy/current/theme/colors.toml"
SIZE="${XCURSOR_SIZE:-24}"

fail=0
note() {
  echo "FAIL: $*"
  fail=1
}

theme_now=$(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null)
mode=$(omarchy-theme-color --file "$COLORS" mode 2>/dev/null) || mode=""
accent=$(omarchy-theme-color --file "$COLORS" accent 2>/dev/null) || accent=""
expected=$(python3 "$CONF/pick.py" --mode "${mode:-dark}" --accent "${accent:-#808080}" 2>/dev/null) || expected=""

login_theme=$(cat "$STATE/login-theme" 2>/dev/null)
login_cursor=$(cat "$STATE/login-cursor" 2>/dev/null)
env_d=$(sed -n 's/^export XCURSOR_THEME=//p' "$ENV_FILE" 2>/dev/null)
invisible=$(hyprctl getoption cursor:invisible 2>/dev/null | head -1)

echo "boot             : $(uptime -p 2>/dev/null)"
echo "theme at login   : ${login_theme:-unknown}"
echo "theme now        : $theme_now (${mode:-?} ${accent:-?})"
echo "cursor at login  : ${login_cursor:-unknown}"
echo "cursor expected  : ${expected:-unknown}"
echo "XCURSOR_THEME    : ${XCURSOR_THEME:-unset}"
echo "HYPRCURSOR_THEME : ${HYPRCURSOR_THEME:-unset}"
echo "gsettings        : $(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null)"
echo "env.d file       : $env_d"
echo "cursor:invisible : $invisible"
echo "configerrors     : [$(hyprctl configerrors 2>&1)]"
echo

# Cold start: what the compositor and its clients inherited at login.
cold="$login_cursor"
if [[ -z $cold ]]; then
  cold="$expected"
  echo "note: no login record yet (login-apply.sh has not run); comparing the"
  echo "      session variables with the current theme instead."
fi
if [[ -z $cold ]]; then
  note "could not resolve the cursor the session should have started with"
else
  [[ ${XCURSOR_THEME:-} == "$cold" ]] ||
    note "cold start: XCURSOR_THEME=${XCURSOR_THEME:-unset}, expected $cold"
  [[ ${HYPRCURSOR_THEME:-} == "$cold" ]] ||
    note "cold start: HYPRCURSOR_THEME=${HYPRCURSOR_THEME:-unset}, expected $cold"
fi

# Live state: gsettings, the env file for the next start, and the compositor.
if [[ -z $expected ]]; then
  note "could not resolve the cursor theme for the current theme"
else
  [[ $env_d == "$expected" ]] || note "live: env.d file does not name $expected"
  [[ $(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null) == "'$expected'" ]] ||
    note "live: gsettings does not name $expected"
  [[ $(hyprctl setcursor "$expected" "$SIZE" 2>&1) == ok ]] ||
    note "live: Hyprland rejected $expected (hyprctl setcursor)"
fi

if [[ -n $login_theme && -n $theme_now && $login_theme != "$theme_now" ]]; then
  echo "note: theme switched since login ($login_theme -> $theme_now); the session"
  echo "      variables hold the login-time values and the hook handled the switch."
fi

# Omarchy hides the cursor for the boot intro and restores it afterwards; if the
# restore never ran, this stays true and the pointer is invisible.
[[ $invisible == "bool: false" ]] ||
  note "cursor:invisible is not false — the startup-cursor restore may not have run"

[[ -z $(hyprctl configerrors 2>&1) ]] || note "Hyprland reports config errors"

echo "result: $([[ $fail == 0 ]] && echo PASS || echo FAIL)"
exit "$fail"
