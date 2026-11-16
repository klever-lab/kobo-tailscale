#!/bin/sh

set -eu
umask 077

# Verify both pins when updating from https://pkgs.tailscale.com/stable/#static.
export TAILSCALE_VERSION=1.104.7
TAILSCALE_SHA256=1c753fef45d497491081db37552b7a2a42c7932292743bf6936cb1a42b6bceb0

task_root=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
cd "$task_root"

echo
echo "Installing tailscale ${TAILSCALE_VERSION} for Kobo Clara BW!"
uname -a
echo

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
tar -xvf "$archive"

echo "Installing iptables into /sbin and /lib ..."
cp binaries/iptables/sbin/* /sbin
cp binaries/iptables/lib/* /lib

ln -sf /sbin/xtables-multi /sbin/iptables
ln -sf /lib/libxtables.so.10.0.0 /lib/libxtables.so.10
ln -sf /lib/libip4tc.so.0.1.0 /lib/libip4tc.so.0
ln -sf /lib/libip6tc.so.0.1.0 /lib/libip6tc.so.0

echo "Installing tailscale binaries into /mnt/onboard/tailscale and symlinking them into /usr/bin ..."
mkdir -p /mnt/onboard/tailscale
mv tailscale_${TAILSCALE_VERSION}_arm/tailscale /mnt/onboard/tailscale
mv tailscale_${TAILSCALE_VERSION}_arm/tailscaled /mnt/onboard/tailscale

# Symlink tailscale binaries to /usr/bin
ln -sf /mnt/onboard/tailscale/tailscale /usr/bin/tailscale
ln -sf /mnt/onboard/tailscale/tailscaled /usr/bin/tailscaled

echo "Cleaning up tarball ..."
rm -rf tailscale_${TAILSCALE_VERSION}_arm
rm -rf tailscale_${TAILSCALE_VERSION}_arm.tgz

echo "Installing tailscale boot and load scripts into /usr/local/tailscale ..."
mkdir -p /usr/local/tailscale
cp scripts/* /usr/local/tailscale

echo "Installing tailscale udev rule into /etc/udev/rules.d ..."
cp rules/* /etc/udev/rules.d

echo
echo "Installation complete! Attempting to boot tailscale daemon ..."
/usr/local/tailscale/boot.sh
echo

echo "If no errors were reported, tailscale should be installed!"
echo "Authenticate with: tailscale up --accept-dns=false --accept-routes=false --ssh=false"
echo "The tailscale binaries are located in /mnt/onboard/tailscale."
echo
