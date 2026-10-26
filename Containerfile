# ----------------------------------------------------------------------
# Base image – slim Debian (trixie) with the latest security updates
# ----------------------------------------------------------------------
FROM docker.io/debian:trixie-20251229-slim

# ---------------------------------------------------------------
# Public ports (fixed, documented in README):
#   55455/tcp -> Privoxy HTTP/HTTPS forward proxy (front door)
#   9050/tcp  -> Tor SOCKS5 (reachable from the network)
# ---------------------------------------------------------------
# repository url
ENV REPO_URL=https://github.com/eduardoenemark/containers-tor-proxy

# build date/time
ARG CREATED_DATETIME
ENV CREATED_DATETIME=${CREATED_DATETIME}

# ------------------------------------------------------------------
# 2. Labels – OCI image metadata + extra documentation labels
# ------------------------------------------------------------------
LABEL org.opencontainers.image.ref.name="tor-proxy" \
      org.opencontainers.image.version="1.2" \
      org.opencontainers.image.authors="@eduardoenemark" \
      org.opencontainers.image.source="${REPO_URL}" \
      org.opencontainers.image.title="TOR Proxy: Privoxy + TOR" \
      org.opencontainers.image.description="A tiny container that runs Tor, wraps it in Privoxy and exposes a forward-proxy on 55455." \
      org.opencontainers.image.created="${CREATED_DATETIME}" \
      org.opencontainers.image.licenses="GPL-3.0-only" \
      org.opencontainers.image.purpose="Privoxy HTTP/HTTPS forward proxy for Tor" \
      org.opencontainers.image.vendor="t.me/eduardoenemark" \
      org.opencontainers.image.url="${REPO_URL}" \
      org.opencontainers.image.documentation="${REPO_URL}" \
      maintainer="Eduardo Vieira <eduardoenemark@gmail.com>"

# ------------------------------------------------------------------
# 3. Install required packages
# ------------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates privoxy tor && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

# ---------------------------------------------------------------
# 4. Copy our configuration files
# ---------------------------------------------------------------
COPY privoxy-config /etc/privoxy/config
COPY torrc /etc/tor/torrc
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# ------------------------------------------------------------------
# 5. Expose the public ports
# ------------------------------------------------------------------
EXPOSE 55455/tcp
EXPOSE 9050/tcp

# ------------------------------------------------------------------
# 6. Entrypoint – starts Tor and Privoxy, handles SIGTERM gracefully.
#    If either daemon dies the container exits so the restart policy
#    (restart: always) brings everything back.
# ------------------------------------------------------------------
CMD ["/usr/local/bin/entrypoint.sh"]
