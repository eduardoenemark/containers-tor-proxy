# ----------------------------------------------------------------------
# Base image – slim Debian (trixie) with the latest security updates
# ----------------------------------------------------------------------
FROM docker.io/debian:trixie-20251229-slim

# ---------------------------------------------------------------
# 1. Port variable – makes it easy to change the public port later
# ---------------------------------------------------------------
# default public listening port
ENV TOR_PROXY_PORT=55455

# internal Tor control / SOCKS port (fixed)
ENV TOR_SOCKET_PORT=55456
ENV DEFAULT_TOR_PORT=9050

# repository url
ENV REPO_URL=https://github.com/eduardoenemark/containers/tree/main/tor-proxy

# build date/time
ARG CREATED_DATETIME
ENV CREATED_DATETIME=${CREATED_DATETIME}

# ------------------------------------------------------------------
# 2. Labels – OCI image metadata + extra documentation labels
# ------------------------------------------------------------------
LABEL org.opencontainers.image.ref.name="tor-proxy" \
      org.opencontainers.image.version="1.1" \
      org.opencontainers.image.authors="@eduardoenemark" \
      org.opencontainers.image.source="${REPO_URL}" \
      org.opencontainers.image.title="TOR Proxy: Socat + Privoxy + TOR" \
      org.opencontainers.image.description="A tiny container that runs Tor, wraps it in Privoxy and exposes a forward‑proxy on ${TOR_PROXY_PORT}." \
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
    apt-get install -y --no-install-recommends ca-certificates socat privoxy tor && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

# ---------------------------------------------------------------
# 4. Copy our configuration files (keep them outside of the image)
# ---------------------------------------------------------------
COPY privoxy-config /etc/privoxy/config

# ------------------------------------------------------------------
# 5. Declare runtime volumes – they are useful for persistence & debugging
# ------------------------------------------------------------------
VOLUME ["/var/log","/var/log/tor","/var/log/privoxy"]

# ------------------------------------------------------------------
# 6. Expose the public port (the value comes from the variable above)
# ------------------------------------------------------------------
EXPOSE ${TOR_PROXY_PORT}/tcp
EXPOSE ${DEFAULT_TOR_PORT}/tcp

# ------------------------------------------------------------------
# 7. Entrypoint – start Tor, Privoxy and Socat in the background
# ------------------------------------------------------------------
CMD ["/bin/bash","-c",\
    "tor 2>&1 | tee -a /var/log/tor/notices.log & \
     privoxy /etc/privoxy/config 2>&1 | tee -a /var/log/privoxy/logfile & \
     socat TCP4-LISTEN:${TOR_PROXY_PORT},fork,reuseaddr TCP4:127.0.0.1:${TOR_SOCKET_PORT} 2>&1 | tee -a /var/log/socat.log"]
