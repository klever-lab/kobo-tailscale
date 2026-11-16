#!/bin/sh
set -eu
install_root=/usr/local/tailscale
timeout 5 "$install_root/bin/tailscale" --socket=/var/run/tailscale/tailscaled.sock down >/dev/null 2>&1 || true
[ -f "$install_root/state/daemon.pid" ] || exit 0
pid=$(cat "$install_root/state/daemon.pid")
case "$pid" in
  ''|*[!0-9]*) echo 'Invalid daemon PID.' >&2; exit 1 ;;
esac
[ "$(readlink "/proc/$pid/exe" 2>/dev/null || true)" = "$install_root/bin/tailscaled" ] || exit 0
kill -TERM "$pid"
attempt=0
while kill -0 "$pid" 2>/dev/null; do
  attempt=$((attempt + 1))
  [ "$attempt" -lt 10 ] || { echo 'Daemon has not stopped; refusing to remove its files.' >&2; exit 1; }
  sleep 1
done
rm -f "$install_root/state/daemon.pid"
