# Kobo Clara BW

This fork's Clara BW installer pins Tailscale 1.104.7 and verifies the official ARM
archive's SHA-256 before changing installed files. It can run from any working
directory. Upstream reported this device working with firmware 4.39.23027 and
Linux 4.9.77; this fork still needs verification on the physical reader.

## Before installing

Back up `.kobo/Kobo/Kobo eReader.conf` and the reader's library outside Git. Check
the installed firmware before choosing a launcher. On a stock reader, NickelMenu
can launch the installer while keeping the stock reading interface;
[NickelMenu does not currently support firmware 5.x](https://pgaskin.net/NickelMenu/).

The installer needs a root shell and the Clara BW kernel's TUN support. It uses
upstream's bundled iptables binaries and libraries, originally from the
[July 5th 2017 Raspbian build](http://downloads.raspberrypi.org/raspbian/images/raspbian-2017-07-05/)
to match the reader's glibc. It does not replace the firmware.

## Install and authenticate

1. Copy this repository to the reader's onboard storage.
2. Optionally copy the verified `tailscale_1.104.7_arm.tgz` into `clara-bw/` to
   avoid downloading it on the reader. The installer verifies this archive too.
3. Disconnect USB, enable Wi-Fi, and run `sh /mnt/onboard/kobo-tailscale/clara-bw/install-tailscale.sh`
   from the reader's root shell or launcher.
4. Authenticate with:

   ```sh
   tailscale up --accept-dns=false --accept-routes=false --ssh=false
   ```

The Wi-Fi reconnect script uses the same options. DNS acceptance remains disabled
to keep Tailscale from overwriting Kobo's DNS settings. Private HTTPS hostnames
therefore need a resolver or local hostname mapping that resolves them to their
Tailscale addresses; keep the hostname for HTTPS certificate validation.

Device connectivity log uploads are disabled. The daemon writes its local log to
`/tailscaled.log` and preserves the existing identity in `/mnt/onboard/tailscale`.
Keep that directory and any enrollment keys outside Git. Reinstalling replaces
binaries without deleting the identity; reboot after updating a running daemon.

Firmware upgrades may require reinstalling the boot scripts. Verify connectivity
after an upgrade and after sleep, Wi-Fi reconnects and USB transfers before
relying on unattended sync.

## Uninstall

Back up the identity first if it must be retained. Upstream's
`uninstall-tailscale.sh` removes `/mnt/onboard/tailscale`, including the identity.
