# TOR Proxy Container

A lightweight container that runs [Tor](https://www.torproject.org), wraps it in Privoxy, and exposes a forward-proxy on port 55455. This proxy service works well with HTTPS, offering good data communication performance.

It's possible to browse the web, watch videos, and download files without lag. Keep in mind that if your Internet connection is slow, your experience will be poor.

When the container starts, the Tor circuit participation process is established. From start to connection establishment, it can take a few minutes. Please be patient during this time.

## What This Container Does

This container sets up a secure proxy that:
- Routes your internet traffic through the Tor network
- Provides both HTTP/HTTPS proxy functionality
- Offers good performance for data communication
- Protects your privacy by anonymizing your traffic

## Quick Start

### Using Docker Compose (Recommended)

1. Create a `docker-compose.yml` file with the following content:

```yaml
version: '3.8'
services:
  tor-proxy:
    image: docker.io/eduardoenemark/tor-proxy:1.1
    container_name: tor-proxy
    restart: always
    stop_grace_period: 5s
    ports:
      # Expose the Tor proxy port
      - "0.0.0.0:55455:55455/tcp"
      # Optional: Expose the default Tor SOCKS port
      - "0.0.0.0:9050:9050/tcp"
    volumes:
      - "~/.cache/log/tor-proxy:/var/log"
      - "~/.cache/log/tor-proxy/privoxy:/var/log/privoxy"
      - "~/.cache/log/tor-proxy/tor:/var/log/tor"
    deploy:
      resources:
        limits:
          cpus: 1
          memory: 512m
```

2. Run the container:
```bash
docker-compose up -d
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
  --cpus 1 \
  --memory 512m \
  docker.io/eduardoenemark/tor-proxy:1.1
```

## Configuration

### Ports

- **55455/tcp**: HTTP/HTTPS proxy port (default).
- **9050/tcp**: Tor SOCKS proxy port (optional).

### Volumes

The container uses these volumes for persistent logging:
- `/var/log`: Main log directory.
- `/var/log/tor`: Tor service logs.
- `/var/log/privoxy`: Privoxy service logs.

## Usage

### For HTTP/HTTPS Traffic

Configure your applications to use the proxy:
- Host: `localhost` or `127.0.0.1`
- Port: `55455`
- Protocol: HTTP/HTTPS

### For Tor Applications

If you need direct Tor access:
- Host: `localhost` or `127.0.0.1`
- Port: `9050`
- Protocol: SOCKS5

## Requirements

- Docker or Podman installed on your system
- At least 512MB RAM available for the container
- Port 55455 (and optionally 9050) available on your host machine

## Logs

All logs are stored in `~/.cache/log/tor-proxy/` directory on your host machine. This includes:
- Tor service logs
- Privoxy service logs
- Socat service logs

## Security Note

Always review the security implications of using any proxy service. Learn more about the Tor network before using this service.

## Troubleshooting

If you encounter issues:
1. Check that port 55455 is not already in use.
2. Verify that the log directories have proper permissions.
3. Check the container logs with `docker logs tor-proxy` or `podman logs tor-proxy`.

## License

This project is licensed under [GPL-3.0](https://www.gnu.org/licenses/gpl-3.0.html).
