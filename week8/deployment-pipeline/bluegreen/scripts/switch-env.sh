#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-}"

if [[ "$TARGET" != "blue" && "$TARGET" != "green" ]]; then
  echo "Usage: $0 {blue|green}"
  exit 1
fi

ACTIVE_FILE="/opt/kijanikiosk/.active-env"
PREVIOUS_FILE="/opt/kijanikiosk/.previous-env"
NGINX_CONF="/etc/nginx/kijanikiosk-active-env.conf"

CURRENT="$(cat "$ACTIVE_FILE" 2>/dev/null || echo unknown)"

if [[ "$TARGET" == "blue" ]]; then
  PORT=3000
  SERVICE="kk-api-blue.service"
  EXPECTED_VERSION="v1.3.0"
else
  PORT=3001
  SERVICE="kk-api-green.service"
  EXPECTED_VERSION="v1.4.0"
fi

echo "[$(date -u '+%Y-%m-%d %H:%M:%S UTC')] Requested switch: $CURRENT -> $TARGET"

if ! systemctl is-active --quiet "$SERVICE"; then
  echo "ERROR: Target service $SERVICE is not active"
  exit 1
fi

DIRECT_HEALTH="$(curl -fsS --max-time 3 "http://127.0.0.1:${PORT}/health")"

if ! echo "$DIRECT_HEALTH" | grep -q "\"version\":\"${EXPECTED_VERSION}\""; then
  echo "ERROR: Target service is not serving expected version ${EXPECTED_VERSION}"
  echo "$DIRECT_HEALTH"
  exit 1
fi

echo "Target health check passed:"
echo "$DIRECT_HEALTH"

cat > "$NGINX_CONF" <<NGINX
upstream kijanikiosk_active {
    server 127.0.0.1:${PORT};
}
NGINX

/usr/sbin/nginx -t
systemctl reload nginx

echo "Waiting for nginx to serve ${EXPECTED_VERSION}..."

PROXY_OK=false

for ATTEMPT in {1..10}; do
  PROXY_HEALTH="$(curl -fsS --max-time 3 http://127.0.0.1:80/health 2>/dev/null || true)"

  if echo "$PROXY_HEALTH" | grep -q "\"version\":\"${EXPECTED_VERSION}\""; then
    PROXY_OK=true
    break
  fi

  echo "Attempt ${ATTEMPT}: proxy has not switched yet"
  sleep 1
done

if [[ "$PROXY_OK" != "true" ]]; then
  echo "ERROR: nginx did not begin serving ${EXPECTED_VERSION}"
  exit 1
fi

echo "$CURRENT" > "$PREVIOUS_FILE"
echo "$TARGET" > "$ACTIVE_FILE"

echo "[$(date -u '+%Y-%m-%d %H:%M:%S UTC')] Switch complete"
echo "active=$(cat "$ACTIVE_FILE")"
echo "previous=$(cat "$PREVIOUS_FILE")"
echo "Proxy health:"
echo "$PROXY_HEALTH"
