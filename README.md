# proxyt-ts-fly

Run [ProxyT](https://github.com/jaxxstorm/proxyt) on [Fly.io](https://fly.io/) exposed publicly through [Tailscale Funnel](https://tailscale.com/kb/1223/funnel).

ProxyT is a proxy for the Tailscale coordination platform, intended for users who cannot access it directly. The Fly VM has no public IP — ProxyT is made publicly available exclusively through Tailscale Funnel.

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

Once deployed, ProxyT will be publicly available via Tailscale Funnel at `https://<your-node-name>.<tailnet>.ts.net`.

## How it works

```
Internet ──▶ Tailscale Funnel ──▶ Fly VM (no public IP)
                                    ├── tailscaled
                                    │     └── tailscale funnel → 127.0.0.1:8080
                                    └── proxyt (127.0.0.1:8080, http-only)
                                          └── state → /data/tailscale (RootFS)
```

- **ProxyT** runs in HTTP-only mode on `127.0.0.1:8080` — publicly accessible only through Tailscale Funnel.
- **Tailscale** connects the VM to your Tailnet, runs `tailscale funnel` to publicly expose port 8080, and advertises the node as an exit node with SSH enabled.
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

- No public IP is allocated — the `fly.toml` has no `[[services]]` or `[http_service]` section. ProxyT is publicly reachable only through Tailscale Funnel.
- ProxyT runs in HTTP-only mode on localhost; Tailscale Funnel handles TLS termination.
- Tailscale state is persisted on the RootFS so the node identity survives restarts.
- IPv4/IPv6 forwarding and NAT masquerading are enabled for exit-node functionality.