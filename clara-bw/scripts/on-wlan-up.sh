#!/bin/sh
set -eu
exec /usr/local/tailscale/bin/tailscale up \
  --accept-dns=false --accept-routes=false --ssh=false --shields-up --netfilter-mode=off --timeout=30s "$@"
