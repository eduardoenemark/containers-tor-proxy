# TOR Proxy Container

A lightweight container that runs [Tor](https://www.torproject.org) and wraps it in [Privoxy](https://www.privoxy.org), exposing an **HTTP/HTTPS forward proxy on port 55455** — plus Tor's native **SOCKS5 on port 9050**.

Traffic flow: `client -> Privoxy (55455) -> Tor SOCKS5 (9050) -> Tor network`.
Privoxy uses `forward-socks5t`, which enables the Tor *optimistic data* extension and reduces latency on the first request of each connection.

## Performance expectations

Tor is inherently slower than a direct connection: expect higher latency and lower throughput. In practice you can browse the web, watch videos and download files comfortably on a decent connection — but keep in mind that some sites (banks, aggressive CDNs) block Tor exit nodes and may refuse to load at all.

On first start, Tor needs to bootstrap its circuits. This usually takes a few seconds up to a couple of minutes depending on your network. Requests made before bootstrap finishes will fail — just retry. Persisting `/var/lib/tor` (see Volumes) makes restarts much faster because guard information is kept.

## Quick Start

### Using Docker Compose (recommended)

1. Create a `docker-compose.yml` file with the following content:

```yaml
services:
  tor-proxy:
    image: docker.io/eduardoenemark/tor-proxy:1.2
    container_name: tor-proxy
    restart: always
    stop_grace_period: 5s
    ports:
      # HTTP/HTTPS forward proxy (Privoxy -> Tor)
      - "0.0.0.0:55455:55455/tcp"
      # Tor SOCKS5 (usable by other machines on the network)
      - "0.0.0.0:9050:9050/tcp"
    volumes:
      - "~/.cache/log/tor-proxy:/var/log"
      - "~/.cache/log/tor-proxy/privoxy:/var/log/privoxy"
      - "~/.cache/log/tor-proxy/tor:/var/log/tor"
      # persist Tor state (guard nodes, circuits) -> faster bootstrap on restart
      - "~/.cache/data/tor-proxy:/var/lib/tor"
    deploy:
      resources:
        limits:
          cpus: 1
          memory: 512m
```

2. Run the container:
```bash
docker compose up -d
```

### Using Podman

```bash
podman run \
  --name tor-proxy \
  --restart always \
  --stop-timeout 5 \
  --publish 0.0.0.0:55455:55455/tcp \
  --publish 0.0.0.0:9050:9050/tcp \
  --volume ~/.cache/log/tor-proxy:/var/log \
  --volume ~/.cache/log/tor-proxy/privoxy:/var/log/privoxy \
  --volume ~/.cache/log/tor-proxy/tor:/var/log/tor \
  --volume ~/.cache/data/tor-proxy:/var/lib/tor \
  --cpus 1 \
  --memory 512m \
  docker.io/eduardoenemark/tor-proxy:1.2
```

## Configuration

### Ports

- **55455/tcp**: HTTP/HTTPS forward proxy (Privoxy -> Tor).
- **9050/tcp**: Tor SOCKS5 proxy, bound to all interfaces — other machines on your network can use it directly.

### Volumes

| Container path | Purpose |
|---|---|
| `/var/log/tor` | Tor notices log (`notices.log`) |
| `/var/log/privoxy` | Privoxy request log (`logfile`) |
| `/var/lib/tor` | Tor state (guard nodes, circuits). **Persist it** — bootstrap after a restart becomes much faster. |

## Usage

- **On the machine running the container:** use `localhost` / `127.0.0.1` as host.
- **From other machines on your network:** use the IP or hostname of the machine running the container.

### HTTP/HTTPS traffic (port 55455)

Configure your application/browser to use an **HTTP proxy** at `<host>:55455`:

```bash
# curl
curl -x http://<host>:55455 https://example.com

# Python requests
proxies = {"http": "http://<host>:55455", "https": "http://<host>:55455"}
```

### SOCKS5 (port 9050)

For applications that speak SOCKS5 directly:

```bash
curl --socks5-hostname <host>:9050 https://example.com
```

## Logs

All logs are stored in `~/.cache/log/tor-proxy/` on the host:

- **Tor:** `tor/notices.log` (bootstrap progress, warnings)
- **Privoxy:** `privoxy/logfile` (one line per request; enable `debug` in `/etc/privoxy/config` only when troubleshooting)

## Security Note

- The proxy has **no authentication**: anyone who can reach ports 55455/9050 can route traffic through Tor. Only expose these ports on a trusted network (your LAN).
- Because SOCKS5 is bound to all interfaces, Tor logs a `non-loopback address` notice at startup — this is expected for this service.
- Learn about the [Tor network](https://www.torproject.org/) before using any proxy service in production.

## Troubleshooting

1. Check that ports 55455/9050 are not already in use on the host.
2. Verify the log directories exist and are writable (Podman creates them for you).
3. Check container logs: `docker logs tor-proxy` or `podman logs tor-proxy`.
4. If requests fail right after a start, Tor is probably still bootstrapping — watch `tor/notices.log` until it reaches `Bootstrapped 100% (done)`.

## License

This project is licensed under [GPL-3.0](https://www.gnu.org/licenses/gpl-3.0.html).
