#!/usr/bin/env bash
set -euo pipefail

ACTIVE_FILE="/opt/kijanikiosk/.active-env"
PREVIOUS_FILE="/opt/kijanikiosk/.previous-env"
SWITCH_SCRIPT="/opt/kijanikiosk/scripts/switch-env.sh"

ACTIVE="$(cat "$ACTIVE_FILE")"
PREVIOUS="$(cat "$PREVIOUS_FILE")"

echo "[$(date -u '+%Y-%m-%d %H:%M:%S UTC')] Rollback requested"
echo "Current active: $ACTIVE"
echo "Rollback target: $PREVIOUS"

if [[ "$PREVIOUS" != "blue" && "$PREVIOUS" != "green" ]]; then
  echo "ERROR: Invalid previous environment: $PREVIOUS"
  exit 1
fi

bash "$SWITCH_SCRIPT" "$PREVIOUS"

echo "[$(date -u '+%Y-%m-%d %H:%M:%S UTC')] Rollback complete"
