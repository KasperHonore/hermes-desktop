#!/bin/bash
# Disable nginx basic auth — access is controlled by Tailscale ACLs
sed -i 's/^\s*auth_basic/#auth_basic/g' /etc/nginx/sites-enabled/default
