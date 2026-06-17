# Hermes Desktop Container

Run [Hermes Desktop](https://github.com/NousResearch/hermes-agent) in a browser — including on mobile devices.

The Electron app runs inside a [KasmVNC](https://kasmweb.com/kasmvnc) container with a built-in web client that provides auto-resize, virtual keyboard, and clipboard sync.

## How it works

A GitHub Actions workflow runs daily and on every push to `main`:

1. Clones the latest [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent)
2. Builds the Electron desktop app for Linux
3. Packages it into a KasmVNC container image
4. Pushes to `ghcr.io/kasperhonore/hermes-desktop:latest`

On your server, [Watchtower](https://containrrr.dev/watchtower/) checks for new images hourly and auto-restarts the container.

## Prerequisites

- A running Hermes Agent backend (the [official Docker container](https://github.com/NousResearch/hermes-agent) or a local install)
- The backend's session token (found in the dashboard logs on first startup)
- Docker and Docker Compose on the host machine

## Quick start

1. Copy the compose file and environment template:

```bash
curl -O https://raw.githubusercontent.com/KasperHonore/hermes-desktop/main/docker-compose.yml
curl -O https://raw.githubusercontent.com/KasperHonore/hermes-desktop/main/.env.example
```

2. Create your `.env` file:

```bash
cp .env.example .env
```

3. Edit `.env` with your backend URL and token:

```
HERMES_DESKTOP_REMOTE_URL=http://your-hermes-backend:9119
HERMES_DESKTOP_REMOTE_TOKEN=your-session-token-here
```

4. Start the containers:

```bash
docker compose up -d
```

5. Open `http://localhost:3000` in your browser.

## Architecture

```
┌─────────────────────────────────────────┐
│  Your server                            │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ hermes-desktop container          │  │
│  │                                   │  │
│  │  KasmVNC ─► Electron app ─────────┼──┼──► Hermes Agent backend
│  │   :3000      (Hermes Desktop)     │  │     (remote, via Tailscale
│  └───────────────────────────────────┘  │      or local network)
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ watchtower container              │  │
│  │  checks GHCR hourly for updates   │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
         ▲
         │ browser (desktop or mobile)
         │
       You
```

## Configuration

All configuration is done through environment variables in your `.env` file:

| Variable | Description | Default |
|---|---|---|
| `HERMES_DESKTOP_REMOTE_URL` | URL of your Hermes Agent backend | *(required)* |
| `HERMES_DESKTOP_REMOTE_TOKEN` | Session token for backend authentication | *(required)* |
| `DISABLE_AUTH` | Disable KasmVNC basic auth (set `true` only when secured by Tailscale) | `false` |
| `PUID` | User ID for file permissions | `1000` |
| `PGID` | Group ID for file permissions | `1000` |
| `TZ` | Container timezone | `Etc/UTC` |

The container exposes port `3000` by default. Change the port mapping in `docker-compose.yml` if needed.

## Unraid

Hermes Desktop is available as an Unraid Community Application. Search for "Hermes Desktop" in the Apps tab, or install manually:

1. In the Unraid Docker tab, click **Add Container**
2. Set **Template Repository** to: `https://github.com/KasperHonore/hermes-unraid-templates`
3. Click **Save**, then select the **hermes-desktop** template
4. Fill in your **Backend URL** and **Backend Token**
5. Click **Apply**

The template pre-configures the standard Unraid appdata path (`/mnt/user/appdata/hermes-desktop`), PUID/PGID (99/100), and `--shm-size=1g`.

### Tailscale on Unraid

There are several ways to use Tailscale with Hermes Desktop on Unraid:

**Accessing the desktop remotely (exposing port 3000 over Tailscale):**

Install the [Tailscale plugin](https://docs.unraid.net/unraid-os/system-administration/secure-your-server/tailscale/) on Unraid. The desktop container is automatically reachable at `http://<unraid-tailscale-ip>:3000` from any device on your Tailnet. No per-container configuration needed.

On Unraid 7+, you can also enable "Use Tailscale" on the container for a dedicated HTTPS URL (`https://hermes-desktop.your-tailnet.ts.net`). Enable "Serve" in the advanced Tailscale settings for automatic TLS certificates.

**Connecting to a remote backend over Tailscale:**

If your Hermes Agent backend runs on a different machine with Tailscale, use its Tailscale IP as the backend URL:

```
HERMES_DESKTOP_REMOTE_URL=http://100.x.x.x:9119
```

For bridge-mode containers to reach Tailscale IPs, you have three options:

1. **Host network mode** — Change the container's network to `host` in the Unraid Docker settings. The container shares the host's Tailscale connection directly.

2. **"Use Tailscale" toggle (Unraid 7+)** — Enable per-container Tailscale in the Docker settings. The container gets its own Tailnet identity and can reach other Tailscale nodes.

3. **Tailscale sidecar** — Run a `tailscale/tailscale` container and set hermes-desktop's network to `container:tailscale`. See the [Unraid Tailscale docs](https://docs.unraid.net/unraid-os/system-administration/secure-your-server/tailscale/) for details.

**Disabling KasmVNC auth with Tailscale:**

When the container is only accessible via Tailscale (not exposed on the LAN), you can disable the KasmVNC login screen by setting `DISABLE_AUTH=true`. Tailscale's identity-based ACLs handle access control at the network layer.

## Manual update

To pull the latest image manually without waiting for Watchtower:

```bash
docker compose pull desktop
docker compose up -d desktop
```
