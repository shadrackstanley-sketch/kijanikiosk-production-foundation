#!/usr/bin/env bash
set -euo pipefail

WINDOW_SECONDS="${1:-60}"
POLL_INTERVAL=5
FAILURE_THRESHOLD=3

ACTIVE_FILE="/opt/kijanikiosk/.active-env"
ROLLBACK_SCRIPT="/opt/kijanikiosk/scripts/rollback.sh"

START_TIME=$(date +%s)
FAILURES=0

echo "[$(date -u '+%Y-%m-%d %H:%M:%S UTC')] Monitor started"
echo "Window: ${WINDOW_SECONDS}s"
echo "Poll interval: ${POLL_INTERVAL}s"
echo "Failure threshold: ${FAILURE_THRESHOLD}"

while true; do
  NOW=$(date +%s)
  ELAPSED=$((NOW - START_TIME))

  if (( ELAPSED >= WINDOW_SECONDS )); then
    echo "[$(date -u '+%Y-%m-%d %H:%M:%S UTC')] Monitor window complete"
    exit 0
  fi

  ACTIVE="$(cat "$ACTIVE_FILE")"

  if [[ "$ACTIVE" == "blue" ]]; then
    EXPECTED_VERSION="v1.3.0"
  elif [[ "$ACTIVE" == "green" ]]; then
    EXPECTED_VERSION="v1.4.0"
  else
    echo "[MONITOR FAIL] Invalid active environment: $ACTIVE"
    exit 1
  fi

  RESPONSE="$(curl -fsS --max-time 3 "http""://127.0.0.1:80/health" 2>/dev/null || true)"

  if echo "$RESPONSE" | grep -Fq "$EXPECTED_VERSION"; then
    FAILURES=0
    echo "[$(date -u '+%Y-%m-%d %H:%M:%S UTC')] HEALTHY active=${ACTIVE} version=${EXPECTED_VERSION}"
  else
    FAILURES=$((FAILURES + 1))

    echo "[$(date -u '+%Y-%m-%d %H:%M:%S UTC')] HEALTH FAILURE ${FAILURES}/${FAILURE_THRESHOLD}"

    if (( FAILURES >= FAILURE_THRESHOLD )); then
      echo "[MONITOR FAIL] ROLLBACK TRIGGERED $(date -u '+%Y-%m-%d %H:%M:%S UTC')"

      bash "$ROLLBACK_SCRIPT"

      echo "[$(date -u '+%Y-%m-%d %H:%M:%S UTC')] Monitor confirmed rollback"
      exit 2
    fi
  fi

  sleep "$POLL_INTERVAL"
done
