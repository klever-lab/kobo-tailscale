#!/bin/sh

set -eu
install_root=/usr/local/tailscale
[ "$(id -u)" = 0 ] || { echo 'Run this uninstaller as root on the reader.' >&2; exit 1; }
for path in "$install_root" "$install_root/bin" "$install_root/state"; do
  [ ! -L "$path" ] || { echo 'Installation directory is a symlink.' >&2; exit 1; }
done
if [ -x "$install_root/on-wlan-down.sh" ]; then
  "$install_root/on-wlan-down.sh"
fi
rm -f /etc/udev/rules.d/98-tailscale.rules
if [ "$(readlink /usr/bin/tailscale 2>/dev/null || true)" = "$install_root/bin/tailscale" ]; then
  rm -f /usr/bin/tailscale
fi
rm -f "$install_root/bin/tailscale" "$install_root/bin/tailscaled"
for script in boot.sh on-boot.sh on-wlan-up.sh on-wlan-down.sh; do
  rm -f "$install_root/$script"
done
echo 'Uninstalled. The private identity and logs remain in /usr/local/tailscale/state.'
