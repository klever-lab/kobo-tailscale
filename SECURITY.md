# Clara BW security review

Reviewed on 2026-11-16 UTC before installation on the connected Clara BW
(firmware 4.46.23852, Linux 4.9.77).

| Finding | Resolution |
| --- | --- |
| Inherited installer overwrote system firewall binaries with opaque 2017 builds. | Removed the bundle after both exact-daemon and physical-reader checks succeeded without it. Netfilter `off` alone does not prove that backend initialization succeeds. |
| Node identity and executable binaries lived on USB-visible FAT storage. | Install on the system partition, with root-only directory access. Reject insufficient space and symlinked installation/state paths. |
| Uninstall deleted the enrolled identity and targeted the wrong boot rule. | Remove only owned program files and the correct rule; retain private state. |
| Download or platform mismatch could affect a root installation. | Verify the official archive's pinned SHA-256 before extraction; reject other models, firmware families and existing conflicting installations. |
| A broad personal identity would give the reader unnecessary tailnet access. | Deployment must use a separate tag and a single-use enrollment key limited by policy to the Books HTTPS service. |

The Tailscale archive is the publisher's static ARM build, version 1.104.7.
The prepared NickelMenu 0.6.0 archive matched its publisher's GitHub asset digest;
its only payloads are `libnm.so` and its configuration documentation. Archive
members were checked for unexpected paths, links and device files.

The [current Tailscale bulletins](https://tailscale.com/security-bulletins) were
reviewed. This version includes the published 1.104.4 and 1.104.7 fixes. SSH,
Serve, Funnel, subnet routing and exit-node service are not enabled on the reader.

ShellCheck and isolated installer tests cover failure before system writes,
private filesystem permissions, identity retention and unrelated-file retention.
The tests do not establish physical TUN, TLS or sleep/reconnect behavior; those
require separate verification on the reader.

The exact official ARM 1.104.7 daemon was also run through QEMU in an isolated
network namespace with iptables and ip6tables absent. It created its TUN engine,
reported `NeedsLogin`, selected nftables, and accepted netfilter mode `off` with
shields-up enabled. This isolated check does not establish compatibility with the
Kobo's kernel or authenticated packet flow.

The physical Clara BW subsequently passed those checks on firmware 4.46.23852
and Linux 4.9.77. Native logs recorded TUN engine creation, iptables and ip6tables
absent, and successful nftables selection. After enrollment with the restricted
tag, the reader fetched the private Books HTTPS login page with certificate
validation enabled. The old firewall bundle was absent from the staged installer
and was not installed. It is now removed from the repository. Cold boot, sleep,
Wi-Fi changes and a complete book sync still need verification; these checks
do not establish compatibility with other firmware or kernels.

This review covers the integration and package provenance. It does not certify
the stock firmware, audit all of Tailscale or NickelMenu, or establish a
reproducible source-to-binary build. NickelMenu intentionally runs selected
commands as root. Physical access and USB configuration remain trust boundaries.
Netfilter `off` does not install a host/LAN firewall; tailnet packet filtering
does not protect existing firmware services on the local Wi-Fi network.
