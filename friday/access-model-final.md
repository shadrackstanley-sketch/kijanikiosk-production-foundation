# KijaniKiosk Access Model (Final)

## Purpose

The KijaniKiosk access model follows the principle of least privilege. Each service receives only the permissions required to perform its function while maintaining controlled sharing through ACLs and the `kijanikiosk` group.

---

# Service Accounts

| Account     | Function                       |
| ----------- | ------------------------------ |
| kk-api      | Application API service        |
| kk-payments | Payment processing service     |
| kk-logs     | Logging and monitoring service |

All three service accounts are members of the `kijanikiosk` group.

---

# Directory Access Model

## 1. /opt/kijanikiosk

Purpose:

Top-level application directory.

Ownership:

* Owner: root
* Group: kijanikiosk

Permissions:

* Root has full control.
* Services access only required subdirectories.

---

## 2. /opt/kijanikiosk/config

Purpose:

Stores service environment files.

Ownership:

* Owner: root
* Group: kijanikiosk

Permissions:

* Service accounts can read assigned environment files.
* Service accounts cannot modify configuration.
* Other users have no access.

Security Goal:

Prevent accidental or malicious modification of application configuration.

---

## 3. /opt/kijanikiosk/shared/logs

Purpose:

Shared log storage used by application and monitoring services.

Ownership:

* Owner: root
* Group: kijanikiosk

ACL Configuration:

| Principal   | Access |
| ----------- | ------ |
| kk-api      | rwx    |
| kk-payments | r-x    |
| kk-logs     | rwx    |

Rationale:

* kk-api writes application logs.
* kk-payments reads logs for audit correlation.
* kk-logs performs log collection and monitoring.

---

## 4. /opt/kijanikiosk/health

Purpose:

Stores provisioning and monitoring health reports.

Ownership:

* Owner: kk-logs
* Group: kijanikiosk

Health Report:

```text
/opt/kijanikiosk/health/last-provision.json
```

Permissions:

* kk-logs can create and update reports.
* Members of the kijanikiosk group can read reports.
* Other users have no access.

This directory was added during the Friday production-foundation implementation and was not present in the original Tuesday model.

---

# Logrotate Integration

## Problem

Logrotate creates new files when logs are rotated.

Without ACL inheritance, newly created files can lose the permissions required by service accounts.

Possible consequences:

* kk-api cannot write new log entries.
* kk-payments cannot read logs for audit purposes.
* Monitoring visibility is lost.

## Solution

Default ACLs were configured on:

```text
/opt/kijanikiosk/shared/logs
```

These ACLs automatically apply to new files created during log rotation.

Configured default entries:

* kk-api : rwx
* kk-payments : r-x
* kk-logs : rwx
* kijanikiosk group : rwx

Logrotate was configured with a compatible create policy and tested using forced rotation.

---

# Verification

The access model was verified using:

```bash
getfacl /opt/kijanikiosk
getfacl /opt/kijanikiosk/config
getfacl /opt/kijanikiosk/shared/logs
getfacl /opt/kijanikiosk/health
```

Forced log rotation was executed.

Post-rotation validation:

```bash
sudo -u kk-api touch /opt/kijanikiosk/shared/logs/test-write.tmp
```

Result:

PASS – kk-api retained write access after log rotation.

Health file validation:

```bash
cat /opt/kijanikiosk/health/last-provision.json
```

Result:

PASS – health reports are readable by authorized users.

---

# Summary

The final access model maintains least-privilege access while supporting operational requirements for application logging, payment auditing, monitoring, and automated log rotation. Default ACL inheritance ensures the model remains intact after log rotation events without requiring manual intervention.
