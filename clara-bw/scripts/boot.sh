#!/bin/sh

# Detach from udev. Executables and state live on the private system partition.
env -i PATH=/usr/sbin:/usr/bin:/sbin:/bin setsid /usr/local/tailscale/on-boot.sh >/dev/null 2>&1 &
exit 0
