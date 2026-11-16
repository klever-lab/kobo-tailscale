#!/bin/sh

set -eu
umask 077
export TS_NO_LOGS_NO_SUPPORT=true
export PATH=/usr/sbin:/usr/bin:/sbin:/bin
install_root=/usr/local/tailscale

mkdir -p /var/run/tailscale "$install_root/state"
chmod 700 /var/run/tailscale "$install_root/state"
if [ ! -c /dev/net/tun ]; then
  [ ! -e /dev/net/tun ] || { echo 'Unexpected TUN device path.' >&2; exit 1; }
  mkdir -p /dev/net
  mknod -m 600 /dev/net/tun c 10 200
fi

if [ -f "$install_root/state/daemon.pid" ]; then
  pid=$(cat "$install_root/state/daemon.pid")
  case "$pid" in
    ''|*[!0-9]*) exit 1 ;;
  esac
  if [ "$(readlink "/proc/$pid/exe" 2>/dev/null || true)" = "$install_root/bin/tailscaled" ]; then
    exit 0
  fi
fi
echo "$$" > "$install_root/state/daemon.pid"
exec "$install_root/bin/tailscaled" --statedir="$install_root/state" --socket=/var/run/tailscale/tailscaled.sock \
  > "$install_root/state/daemon.log" 2>&1
