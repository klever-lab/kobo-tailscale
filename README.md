# kobo-tailscale
Install scripts for getting [Tailscale](https://tailscale.com) running on Kobo e-readers and persisting through reboots.

This is Klever's fork of [videah/kobo-tailscale](https://github.com/videah/kobo-tailscale).
Our Clara BW setup uses the [Clara BW instructions](clara-bw/README.md), a pinned
Tailscale release with SHA-256 verification, and DNS acceptance disabled by default.
The other device directories retain upstream's installers.

## Supported devices
- *Kobo Libra 2*
- *Koba Libra Colour*/*Koba Libra Color*
- *Kobo Clara BW*

If you have another device and would like to contribute, please open a PR!

## Installation
> [!NOTE]  
> The Clara BW installer pins both `TAILSCALE_VERSION` and `TAILSCALE_SHA256`.
> Update and verify both together. The other installers use upstream's version variable.

1. Download this repo onto your Kobo e-reader's onboard storage and find your device.
2. Run `install-tailscale.sh` from the chosen device's directory.
3. For Clara BW, run `tailscale up --accept-dns=false --accept-routes=false --ssh=false`
   and follow the instructions to authenticate your e-reader. Follow the upstream
   instructions for the other models.

## Uninstallation
Simply run `uninstall-tailscale.sh` from the chosen device's directory in the repo.

## DNS Issues
When there's no DNS manager on a system, Tailscale will resort to just [overwriting resolv.conf](https://tailscale.com/kb/1235/resolv-conf/)
which can cause issues on Kobo devices. If you find that DNS breaks after a while you can fix this by running
`tailscale set --accept-dns=false` on your device to prevent it from overwriting resolv.conf.

## Acknowledgements
[Dylan Staley for initial work and scripts on the Kobo Sage](https://dstaley.com/posts/tailscale-on-kobo-sage)

[jmacindoe for documenting kernel module compilation on Kobo readers](https://github.com/jmacindoe/kobo-kernel-modules)
