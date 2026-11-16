#!/bin/sh

set -eu
umask 077

# Verify both pins when updating from https://pkgs.tailscale.com/stable/#static.
export TAILSCALE_VERSION=1.104.7
TAILSCALE_SHA256=1c753fef45d497491081db37552b7a2a42c7932292743bf6936cb1a42b6bceb0
install_root=/usr/local/tailscale
export PATH=/usr/sbin:/usr/bin:/sbin:/bin

task_root=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
cd "$task_root"

[ "$(id -u)" = 0 ] || { echo 'Run this installer as root on the reader.' >&2; exit 1; }
[ "$(uname -m)" = armv7l ] || { echo 'This installer requires a Kobo Clara BW.' >&2; exit 1; }
grep -q ' /mnt/onboard ' /proc/mounts || { echo 'Onboard storage is not mounted.' >&2; exit 1; }
case "$(cut -d, -f3 /mnt/onboard/.kobo/version)" in
  4.*) ;;
  *) echo 'Only Kobo firmware 4.x has been reviewed for this installer.' >&2; exit 1 ;;
esac
case "$(cut -d, -f6 /mnt/onboard/.kobo/version)" in
  *000391) ;;
  *) echo 'The attached reader is not a Clara BW.' >&2; exit 1 ;;
esac
for path in "$install_root" "$install_root/bin" "$install_root/state"; do
  [ ! -L "$path" ] || { echo 'Installation directory is a symlink.' >&2; exit 1; }
done
if [ -e /mnt/onboard/tailscale/tailscaled.state ]; then
  echo 'An older USB-visible identity exists. Back it up and migrate it privately first.' >&2
  exit 1
fi
if pidof tailscaled >/dev/null 2>&1; then
  echo 'Stop the running daemon before updating. Its identity will be retained.' >&2
  exit 1
fi
if [ -e /usr/bin/tailscale ] && [ "$(readlink /usr/bin/tailscale)" != "$install_root/bin/tailscale" ]; then
  echo 'Refusing to replace another Tailscale installation.' >&2
  exit 1
fi
available_kb=$(df -Pk /usr/local | awk 'END {print $4}')
[ "$available_kb" -ge 90000 ] || { echo 'At least 90,000 KiB of free system storage is required.' >&2; exit 1; }

# Check the download before changing any installed files. An existing archive can
# be copied here over USB to avoid downloading it on the reader.
archive="tailscale_${TAILSCALE_VERSION}_arm.tgz"
if [ ! -f "$archive" ]; then
  echo "Downloading $archive from pkgs.tailscale.com ..."
  wget -O "$archive.partial" "https://pkgs.tailscale.com/stable/$archive"
  printf '%s  %s\n' "$TAILSCALE_SHA256" "$archive.partial" | sha256sum -c -
  mv "$archive.partial" "$archive"
fi
printf '%s  %s\n' "$TAILSCALE_SHA256" "$archive" | sha256sum -c -
stage=$(mktemp -d /mnt/onboard/.tailscale-install.XXXXXX)
trap 'rm -rf "$stage"' EXIT HUP INT TERM
tar -xzf "$archive" -C "$stage" "tailscale_${TAILSCALE_VERSION}_arm/tailscale" "tailscale_${TAILSCALE_VERSION}_arm/tailscaled"

# Persistent executables, scripts and credentials stay off USB-visible storage.
mkdir -p "$install_root/bin" "$install_root/state"
chmod 700 "$install_root" "$install_root/bin" "$install_root/state"
cp "$stage/tailscale_${TAILSCALE_VERSION}_arm/tailscale" "$install_root/bin/tailscale"
cp "$stage/tailscale_${TAILSCALE_VERSION}_arm/tailscaled" "$install_root/bin/tailscaled"
chmod 700 "$install_root/bin/tailscale" "$install_root/bin/tailscaled"
for script in boot.sh on-boot.sh on-wlan-up.sh on-wlan-down.sh; do
  cp "scripts/$script" "$install_root/$script"
  chmod 700 "$install_root/$script"
done
ln -sf "$install_root/bin/tailscale" /usr/bin/tailscale
cp rules/98-tailscale.rules /etc/udev/rules.d/98-tailscale.rules
chmod 600 /etc/udev/rules.d/98-tailscale.rules
"$install_root/boot.sh"
echo 'Installed. The existing private identity was retained.'
echo 'Authenticate using /usr/local/tailscale/on-wlan-up.sh, with a restricted enrollment key.'
