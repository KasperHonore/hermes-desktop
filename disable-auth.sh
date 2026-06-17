#!/bin/bash
# Optionally disable nginx basic auth when access is secured by Tailscale ACLs
# or another network-layer authentication mechanism.
#
# When DISABLE_AUTH is unset or "false", KasmVNC's built-in basic auth stays
# active (the default credentials are set via CUSTOM_USER / PASSWORD env vars,
# or KasmVNC's own defaults). Set DISABLE_AUTH=true only when the container is
# reachable exclusively through Tailscale or a similarly trusted network.

if [ "${DISABLE_AUTH:-false}" = "true" ]; then
    echo "[hermes-desktop] Disabling KasmVNC basic auth (DISABLE_AUTH=true)"
    sed -i 's/^\s*auth_basic/#auth_basic/g' /etc/nginx/sites-enabled/default
fi
