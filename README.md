# kobo-tailscale
Install scripts for getting [Tailscale](https://tailscale.com) running on the Kobo Clara BW and persisting through reboots.

This is Klever's fork of [videah/kobo-tailscale](https://github.com/videah/kobo-tailscale).
This fork supports the Kobo Clara BW. It uses a pinned Tailscale release with
SHA-256 verification and DNS acceptance disabled by default.

See the [Clara BW instructions](clara-bw/README.md) for firmware requirements,
installation, authentication, DNS configuration, and uninstallation.

The installer pins both `TAILSCALE_VERSION` and `TAILSCALE_SHA256`. Update and
verify both together.

## Acknowledgements
[Dylan Staley for initial work and scripts on the Kobo Sage](https://dstaley.com/posts/tailscale-on-kobo-sage)

[jmacindoe for documenting kernel module compilation on Kobo readers](https://github.com/jmacindoe/kobo-kernel-modules)
