#!/usr/bin/env bash
set -euo pipefail

# Expected dirty conditions found in pre-provisioning audit:
# - kk-api already exists (handled with id check)
# - kk-payments already exists (handled with id check)
# - kk-logs already exists (handled with id check)
# - kijanikiosk group already exists (handled with getent check)
# - /opt/kijanikiosk/config permissions are 777 (corrected in Phase 3)
# - Missing ACL entries for service accounts (corrected in Phase 3)
# - UFW inactive (configured in Phase 5)
# - curl package hold exists (validated in Phase 1)
# - Existing directory structure present (handled via mkdir -p)
# - No systemd service definitions exist (created in Phase 4)

phase() {
  echo
  echo "================================================"
  echo "$1"
  echo "================================================"
}

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; exit 1; }
info() { echo "INFO: $1"; }

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    fail "Run this script with sudo"
  fi
}

require_root

phase "PHASE 1 - Package Validation & Version Checks"

apt-get update -y

for pkg in curl ufw acl logrotate nginx; do
  if dpkg -s "$pkg" >/dev/null 2>&1; then
    info "Already installed: $pkg"
  else
    info "Installing: $pkg"
    apt-get install -y "$pkg"
  fi
done

if apt-mark showhold | grep -qx "curl"; then
  info "Dirty state detected: curl package hold exists"
else
  info "curl is not currently held; applying hold"
  apt-mark hold curl
fi

phase "PHASE 2 - Users and Groups"

if getent group kijanikiosk >/dev/null; then
  info "Already exists: group kijanikiosk"
else
  groupadd --system kijanikiosk
  info "Created group: kijanikiosk"
fi

create_service_user() {
  local user="$1"

  if id "$user" >/dev/null 2>&1; then
    info "Already exists: $user"
    usermod -aG kijanikiosk "$user"
  else
    useradd --system \
      --no-create-home \
      --shell /usr/sbin/nologin \
      --gid kijanikiosk \
      "$user"
    info "Created service account: $user"
  fi
}

create_service_user kk-api
create_service_user kk-payments
create_service_user kk-logs

phase "PHASE 3 - Directories, Permissions & ACLs"

mkdir -p /opt/kijanikiosk/config
mkdir -p /opt/kijanikiosk/shared/logs
mkdir -p /opt/kijanikiosk/health

chown root:kijanikiosk /opt/kijanikiosk
chmod 755 /opt/kijanikiosk

chown root:kijanikiosk /opt/kijanikiosk/config
chmod 750 /opt/kijanikiosk/config

chown root:kijanikiosk /opt/kijanikiosk/shared
chmod 755 /opt/kijanikiosk/shared

chown root:kijanikiosk /opt/kijanikiosk/shared/logs
chmod 2770 /opt/kijanikiosk/shared/logs

chown kk-logs:kijanikiosk /opt/kijanikiosk/health
chmod 750 /opt/kijanikiosk/health

setfacl -m u:kk-api:rwx /opt/kijanikiosk/shared/logs
setfacl -m u:kk-payments:rx /opt/kijanikiosk/shared/logs
setfacl -m u:kk-logs:rwx /opt/kijanikiosk/shared/logs

setfacl -d -m u:kk-api:rwx /opt/kijanikiosk/shared/logs
setfacl -d -m u:kk-payments:rx /opt/kijanikiosk/shared/logs
setfacl -d -m u:kk-logs:rwx /opt/kijanikiosk/shared/logs
setfacl -d -m g:kijanikiosk:rwx /opt/kijanikiosk/shared/logs

info "Corrected config permissions and restored log ACLs"

phase "PHASE 4 - Systemd Service Deployment"

cat >/opt/kijanikiosk/config/api.env <<'EOF'
APP_ENV=production
APP_PORT=3000
EOF

cat >/opt/kijanikiosk/config/payments-api.env <<'EOF'
APP_ENV=production
APP_PORT=3001
EOF

cat >/opt/kijanikiosk/config/logs.env <<'EOF'
APP_ENV=production
APP_PORT=3002
EOF

chown root:kk-api /opt/kijanikiosk/config/api.env
chmod 640 /opt/kijanikiosk/config/api.env

chown root:kk-payments /opt/kijanikiosk/config/payments-api.env
chmod 640 /opt/kijanikiosk/config/payments-api.env

chown root:kk-logs /opt/kijanikiosk/config/logs.env
chmod 640 /opt/kijanikiosk/config/logs.env

sudo -u kk-api cat /opt/kijanikiosk/config/api.env >/dev/null
sudo -u kk-payments cat /opt/kijanikiosk/config/payments-api.env >/dev/null
sudo -u kk-logs cat /opt/kijanikiosk/config/logs.env >/dev/null

cat >/etc/systemd/system/kk-api.service <<'EOF'
[Unit]
Description=KijaniKiosk API Service
After=network.target

[Service]
Type=simple
User=kk-api
Group=kijanikiosk
EnvironmentFile=/opt/kijanikiosk/config/api.env
WorkingDirectory=/opt/kijanikiosk
ExecStart=/bin/bash -c 'while true; do sleep 3600; done'
Restart=always
RestartSec=5

NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/kijanikiosk/shared/logs
CapabilityBoundingSet=
RestrictSUIDSGID=true
LockPersonality=true
MemoryDenyWriteExecute=true
PrivateDevices=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true

[Install]
WantedBy=multi-user.target
EOF

cat >/etc/systemd/system/kk-payments.service <<'EOF'
[Unit]
Description=KijaniKiosk Payments Service
After=network.target kk-api.service
Wants=kk-api.service

[Service]
Type=simple
User=kk-payments
Group=kijanikiosk
EnvironmentFile=/opt/kijanikiosk/config/payments-api.env
WorkingDirectory=/opt/kijanikiosk
ExecStart=/bin/bash -c 'while true; do sleep 3600; done'
Restart=always
RestartSec=5

NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadOnlyPaths=/opt/kijanikiosk/config
ReadWritePaths=/opt/kijanikiosk/shared/logs
CapabilityBoundingSet=
RestrictSUIDSGID=true
LockPersonality=true
MemoryDenyWriteExecute=true
PrivateDevices=true
DevicePolicy=closed
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectKernelLogs=true
ProtectControlGroups=true
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
SystemCallArchitectures=native
SystemCallFilter=@system-service
RestrictRealtime=true
PrivateMounts=true
RemoveIPC=true
UMask=0077
ProtectClock=true
ProtectHostname=true
RestrictNamespaces=true
ProtectProc=invisible
ProcSubset=pid
PrivateUsers=true

[Install]
WantedBy=multi-user.target
EOF

cat >/etc/systemd/system/kk-logs.service <<'EOF'
[Unit]
Description=KijaniKiosk Logs Service
After=network.target

[Service]
Type=simple
User=kk-logs
Group=kijanikiosk
EnvironmentFile=/opt/kijanikiosk/config/logs.env
WorkingDirectory=/opt/kijanikiosk
ExecStart=/bin/bash -c 'while true; do sleep 3600; done'
Restart=always
RestartSec=5

NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/kijanikiosk/shared/logs /opt/kijanikiosk/health
CapabilityBoundingSet=
RestrictSUIDSGID=true
LockPersonality=true
MemoryDenyWriteExecute=true
PrivateDevices=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kk-api.service kk-payments.service kk-logs.service
systemctl restart kk-api.service kk-payments.service kk-logs.service

info "Created and started all three systemd units"

phase "PHASE 5 - Firewall Configuration"

ufw --force reset
ufw default deny incoming
ufw default allow outgoing

ufw allow 22/tcp comment 'SSH administration'
ufw allow 80/tcp comment 'HTTP web traffic'
ufw allow from 10.0.1.0/24 to any port 3001 proto tcp comment 'Monitoring health checks'
ufw allow in on lo to any port 3001 proto tcp comment 'Local reverse proxy access'
ufw deny 3001/tcp comment 'Block external payments port'

ufw --force enable

phase "PHASE 6 - Environment Files & Access Model"

sudo -u kk-api cat /opt/kijanikiosk/config/api.env >/dev/null
sudo -u kk-payments cat /opt/kijanikiosk/config/payments-api.env >/dev/null
sudo -u kk-logs cat /opt/kijanikiosk/config/logs.env >/dev/null

pass "Environment files readable by correct service accounts"

phase "PHASE 7 - Journal Persistence & Log Rotation"

mkdir -p /var/log/journal
mkdir -p /etc/systemd/journald.conf.d

cat >/etc/systemd/journald.conf.d/kijanikiosk.conf <<'EOF'
[Journal]
Storage=persistent
SystemMaxUse=500M
EOF

systemctl restart systemd-journald || true

touch /opt/kijanikiosk/shared/logs/api.log
touch /opt/kijanikiosk/shared/logs/payments.log
touch /opt/kijanikiosk/shared/logs/logs.log

chown kk-api:kijanikiosk /opt/kijanikiosk/shared/logs/api.log
chown kk-api:kijanikiosk /opt/kijanikiosk/shared/logs/payments.log
chown kk-logs:kijanikiosk /opt/kijanikiosk/shared/logs/logs.log

chmod 660 /opt/kijanikiosk/shared/logs/*.log

cat >/etc/logrotate.d/kijanikiosk <<'EOF'
/opt/kijanikiosk/shared/logs/*.log {
    su kk-api kijanikiosk
    daily
    rotate 14
    compress
    missingok
    notifempty
    copytruncate
    create 0660 kk-api kijanikiosk
    sharedscripts
    postrotate
        systemctl restart kk-logs.service >/dev/null 2>&1 || true
    endscript
}
EOF

logrotate --force --debug /etc/logrotate.d/kijanikiosk >/dev/null

pass "Journal persistence and logrotate configured"

phase "PHASE 8 - Health Checks & Final Verification"

api_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/3000" 2>/dev/null && echo '"ok"' || echo '"down"')
payments_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/3001" 2>/dev/null && echo '"ok"' || echo '"down"')
logs_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/3002" 2>/dev/null && echo '"ok"' || echo '"down"')

printf '{"timestamp":"%s","kk-api":%s,"kk-payments":%s,"kk-logs":%s}\n' \
  "$(date -Is)" "$api_status" "$payments_status" "$logs_status" \
  > /opt/kijanikiosk/health/last-provision.json

chown kk-logs:kijanikiosk /opt/kijanikiosk/health/last-provision.json
chmod 640 /opt/kijanikiosk/health/last-provision.json

checks_failed=0

check() {
  local description="$1"
  shift

  if "$@"; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    checks_failed=$((checks_failed + 1))
  fi
}

check "kk-api account exists" id kk-api
check "kk-payments account exists" id kk-payments
check "kk-logs account exists" id kk-logs
check "kijanikiosk group exists" getent group kijanikiosk

check "config directory is not world writable" bash -c '[[ "$(stat -c "%a" /opt/kijanikiosk/config)" != "777" ]]'
check "log directory exists" test -d /opt/kijanikiosk/shared/logs
check "health JSON exists" test -f /opt/kijanikiosk/health/last-provision.json

check "kk-api unit exists" systemctl cat kk-api.service
check "kk-payments unit exists" systemctl cat kk-payments.service
check "kk-logs unit exists" systemctl cat kk-logs.service

check "kk-api service active" systemctl is-active --quiet kk-api.service
check "kk-payments service active" systemctl is-active --quiet kk-payments.service
check "kk-logs service active" systemctl is-active --quiet kk-logs.service

check "UFW active" ufw status
check "SSH firewall rule present" bash -c 'ufw status | grep -q "22/tcp.*ALLOW"'
check "HTTP firewall rule present" bash -c 'ufw status | grep -q "80/tcp.*ALLOW"'
check "3001 monitoring rule present" bash -c 'ufw status | grep -q "10.0.1.0/24"'
check "3001 deny rule present" bash -c 'ufw status | grep -q "3001/tcp.*DENY"'

check "journal config exists" test -f /etc/systemd/journald.conf.d/kijanikiosk.conf
check "logrotate config exists" test -f /etc/logrotate.d/kijanikiosk
check "logrotate debug passes" logrotate --force --debug /etc/logrotate.d/kijanikiosk
check "kk-api can write after logrotate" sudo -u kk-api touch /opt/kijanikiosk/shared/logs/test-write.tmp

if [[ "$checks_failed" -eq 0 ]]; then
  echo
  echo "ALL CHECKS PASSED"
else
  echo
  echo "$checks_failed CHECK(S) FAILED"
  exit 1
fi
