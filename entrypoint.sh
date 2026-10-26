#!/bin/sh
# tor-proxy entrypoint - starts Tor + Privoxy and keeps them alive.
#  - SIGTERM/SIGINT -> graceful shutdown of both daemons (podman stop)
#  - if either daemon dies -> exit non-zero so the container restart
#    policy (restart: always) brings everything back

cleanup() {
    kill "$TOR_PID" "$PRIVOXY_PID" 2>/dev/null
    wait
}
trap 'cleanup; exit 0' TERM INT

tor &
TOR_PID=$!
privoxy --no-daemon /etc/privoxy/config &  # --no-daemon: stay in the foreground so the PID is trackable
PRIVOXY_PID=$!

# monitor both daemons (interruptible sleep so traps fire promptly)
while kill -0 "$TOR_PID" 2>/dev/null && kill -0 "$PRIVOXY_PID" 2>/dev/null; do
    sleep 5 &
    wait $!
done

# a daemon died -> clean up and exit non-zero (restart policy takes over)
cleanup
exit 1
