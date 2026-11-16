#!/bin/sh
set -eu
exec /usr/local/tailscale/bin/tailscale --socket=/var/run/tailscale/tailscaled.sock up \
  --accept-dns=false --accept-routes=false --ssh=false --shields-up --netfilter-mode=off --timeout=30s "$@"
