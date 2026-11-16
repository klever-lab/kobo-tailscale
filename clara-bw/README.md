# Kobo Clara BW

This fork's Clara BW installer pins Tailscale 1.104.7 and verifies the official ARM
archive's SHA-256 before changing installed files. It can run from any working
directory. This fork has passed native Tailscale startup and private HTTPS access
checks on a Clara BW running firmware 4.46.23852 and Linux 4.9.77. The daemon used
nftables with no bundled iptables binaries; see the [verification limits](../SECURITY.md).

## Before installing

Back up `.kobo/Kobo/Kobo eReader.conf` and the reader's library outside Git. Check
the installed firmware before choosing a launcher. On a stock reader, NickelMenu
can launch the installer while keeping the stock reading interface;
[NickelMenu does not currently support firmware 5.x](https://pgaskin.net/NickelMenu/).

The installer needs a root shell, the Clara BW kernel's TUN support and at least
90,000 KiB free on the system partition. It installs the official static binaries
there, along with private state, and leaves system firewall libraries untouched.

## Install and authenticate

1. Copy this repository to the reader's onboard storage.
2. Optionally copy the verified `tailscale_1.104.7_arm.tgz` into `clara-bw/` to
   avoid downloading it on the reader. The installer verifies this archive too.
3. Disconnect USB, enable Wi-Fi, and run `sh /mnt/onboard/kobo-tailscale/clara-bw/install-tailscale.sh`
   from the reader's root shell or launcher.
4. Authenticate with:

   ```sh
   /usr/local/tailscale/on-wlan-up.sh
   ```

The helper disables DNS changes, subnet routes, SSH and unsolicited incoming
tailnet connections. It uses `--netfilter-mode=off` for this outbound client;
it does not advertise routes, provide an exit node or expose any services.
Tailscale handles Wi-Fi reconnects itself. DNS acceptance remains disabled
to keep Tailscale from overwriting Kobo's DNS settings. Private HTTPS hostnames
therefore need a resolver or local hostname mapping that resolves them to their
Tailscale addresses; keep the hostname for HTTPS certificate validation.

Device connectivity log uploads are disabled. Identity and local logs live under
`/usr/local/tailscale/state` with root-only access, outside USB-visible storage.
Stop the daemon with `/usr/local/tailscale/on-wlan-down.sh` before an update.
The installer preserves existing private state and refuses to silently replace
an older identity found on USB storage.

Firmware upgrades may require reinstalling the boot scripts. Verify connectivity
after an upgrade and after sleep, Wi-Fi reconnects and USB transfers before
relying on unattended sync.

## Uninstall

Run `sh uninstall-tailscale.sh` as root. It stops this daemon, removes its binaries
and boot rule, and preserves the private identity. Retire the device through
Tailscale before deliberately erasing retained credentials.

## Security checks

Run ShellCheck on `install-tailscale.sh`, `uninstall-tailscale.sh` and `scripts/*.sh`.
The isolated Linux tests require bubblewrap and the pinned official ARM archive:

```sh
KOBO_TAILSCALE_ARCHIVE=/private/path/tailscale_1.104.7_arm.tgz python3 -m unittest discover -s tests -v
```

Run the tests from the repository root. They fail if prerequisites are missing.
The [security review](../SECURITY.md) records the findings and remaining limits.
