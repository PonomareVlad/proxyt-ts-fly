#!/bin/sh

modprobe xt_mark

echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' | tee -a /etc/sysctl.conf
sysctl -p /etc/sysctl.conf

iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

/app/tailscaled --state=/data/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &
/app/tailscale up --auth-key=${TAILSCALE_AUTHKEY} --hostname=${TAILSCALE_HOSTNAME:-proxyt} --advertise-exit-node --ssh
/app/tailscale funnel --bg 8080

PROXYT_DOMAIN=${PROXYT_DOMAIN:-$(/app/tailscale status --json | grep -o '"DNSName":"[^"]*"' | head -1 | cut -d'"' -f4 | sed 's/\.$//')}
PROXYT_DOMAIN=${PROXYT_DOMAIN:-${TAILSCALE_HOSTNAME:-proxyt}}

exec /app/proxyt serve --http-only --port 8080 --domain "${PROXYT_DOMAIN}"
