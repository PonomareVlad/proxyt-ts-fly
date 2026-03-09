# proxyt-ts-fly

Run [ProxyT](https://github.com/jaxxstorm/proxyt) on [Fly.io](https://fly.io/) with private access through [Tailscale](https://tailscale.com/).

ProxyT is exposed exclusively via Tailscale Funnel, so there is no public endpoint — all access is gated through your Tailnet.

## Prerequisites

- [Fly CLI](https://fly.io/docs/flyctl/install/) (`flyctl`)
- A [Fly.io](https://fly.io/) account
- A [Tailscale](https://tailscale.com/) account and an [auth key](https://tailscale.com/kb/1085/auth-keys)

## Setup

1. **Create the Fly app:**

   ```sh
   fly apps create proxyt-ts-fly
   ```

2. **Set the Tailscale auth key as a secret:**

   ```sh
   fly secrets set TAILSCALE_AUTHKEY=tskey-auth-...
   ```

3. **Deploy:**

   ```sh
   fly deploy
   ```

Once deployed, ProxyT will be available on your Tailnet at `https://proxyt` (if you have MagicDNS enabled) or at `https://<your-node-name>.<tailnet>.ts.net`.

## How it works

```
Internet ──✕──▶ Fly VM (no public IP)
                  ├── tailscaled
                  │     └── tailscale serve → 127.0.0.1:8080
                  └── proxyt (127.0.0.1:8080, http-only)
                        └── state → /data/tailscale (RootFS)

Tailnet ──────▶ Fly VM ──▶ ProxyT
```

- **ProxyT** runs in HTTP-only mode on `127.0.0.1:8080` — not reachable from the internet.
- **Tailscale** connects the VM to your Tailnet, runs `tailscale serve` to proxy port 8080, and advertises the node as an exit node with SSH enabled.
- **Fly.io** provides a shared-cpu-1x VM in `fra` with persistent RootFS for Tailscale state.

## Configuration

| Variable | Description |
|---|---|
| `TAILSCALE_AUTHKEY` | Tailscale auth key used to join your Tailnet (set via `fly secrets set`) |
| `TAILSCALE_HOSTNAME` | Tailscale hostname (default: `proxyt`) |
| `PROXYT_DOMAIN` | ProxyT domain override (auto-detected from Tailscale by default) |

Key settings in `fly.toml`:

| Setting | Value | Notes |
|---|---|---|
| `primary_region` | `fra` | Change to a [region](https://fly.io/docs/reference/regions/) closer to you |
| `vm.size` | `shared-cpu-1x` | Smallest Fly VM tier |
| `vm.persist_rootfs` | `always` | Persist RootFS across restarts and deploys |

## Security

- No public IP is allocated — the `fly.toml` has no `[[services]]` or `[http_service]` section.
- ProxyT runs in HTTP-only mode on localhost; it cannot be reached without Tailscale.
- Tailscale state is persisted on the RootFS so the node identity survives restarts.
- IPv4/IPv6 forwarding and NAT masquerading are enabled for exit-node functionality.