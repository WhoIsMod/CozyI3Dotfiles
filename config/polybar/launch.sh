#!/usr/bin/env bash
# (Re)start polybar. HOME is resolved here and written into a generated copy of the config,
# so the bar works even if the session was started without HOME in its environment.
: "${HOME:=$(getent passwd "$(id -un)" | cut -d: -f6)}"; export HOME
killall -q polybar
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.3; done
mkdir -p "$HOME/.cache/polybar"
sed 's|\${env:HOME}|'"$HOME"'|g' "$HOME/.config/polybar/config.ini" > "$HOME/.cache/polybar/config.ini"
polybar -c "$HOME/.cache/polybar/config.ini" -r main >/dev/null 2>&1 &
