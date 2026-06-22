# Integration Notes

## Introduction

This document describes the resolution of the four Integration Challenges encountered during implementation of the KijaniKiosk Production Server Foundation. Each challenge involved competing requirements that could not be satisfied through a simple configuration change. The goal was to select solutions that balanced security, maintainability, operational reliability, and project requirements.

---

# Integration Challenge A

## Monitoring Access vs Payments Service Isolation

### Conflict

The project required that the payments service port (3001) not be publicly accessible. However, the monitoring system needed access to the same port from the monitoring subnet.

These requirements conflict because one requirement demands access while the other demands isolation.

### Options Considered

#### Option 1: Completely block port 3001

Advantages:

* Maximum network isolation.
* Simplest firewall configuration.

Disadvantages:

* Monitoring system would lose visibility into service health.
* Project requirements would not be met.

#### Option 2: Allow unrestricted access to port 3001

Advantages:

* Monitoring works without additional configuration.

Disadvantages:

* Exposes the payments service to unnecessary network access.
* Violates least-privilege principles.

#### Option 3: Allow access only from the monitoring subnet

Advantages:

* Monitoring continues to function.
* External access remains blocked.
* Supports least-privilege network access.

Disadvantages:

* Requires additional firewall rules.
* Monitoring subnet must remain accurately maintained.

### Decision

Option 3 was selected.

The firewall was configured to allow:

```text
10.0.1.0/24 → port 3001
```

while denying access from all other external sources.

### Reasoning

This approach satisfied both requirements simultaneously. Monitoring retained access while the payments service remained protected from general network exposure.

---

# Integration Challenge B

## Health Reporting Ownership and Visibility

### Conflict

The project required generation of a provisioning health report while also maintaining separation between service responsibilities.

The monitoring service needed write access to the health report, while other authorized services needed read access.

### Options Considered

#### Option 1: Store the health report under root ownership

Advantages:

* Strong administrative control.

Disadvantages:

* Monitoring service cannot update the file directly.
* Additional privilege escalation would be required.

#### Option 2: Make the health directory world-readable

Advantages:

* Easy access for all users.

Disadvantages:

* Violates least-privilege principles.
* Exposes operational information unnecessarily.

#### Option 3: Assign ownership to kk-logs and controlled group access

Advantages:

* Monitoring service can manage reports.
* Authorized services can read reports.
* Other users remain blocked.

Disadvantages:

* Requires careful permission management.

### Decision

Option 3 was selected.

The health directory is owned by:

```text
kk-logs:kijanikiosk
```

The generated report:

```text
last-provision.json
```

is owned by the monitoring service and readable through group permissions.

### Reasoning

This design matches operational responsibility. The monitoring service creates health data while other services receive only the visibility they require.

---

# Integration Challenge C

## Log Rotation vs ACL Persistence

### Conflict

The access model depended on ACLs to provide different permissions to different services.

However, logrotate recreates log files during rotation.

Without additional controls, new files can lose ACL entries and break service access.

### Options Considered

#### Option 1: Use only standard UNIX permissions

Advantages:

* Simple configuration.

Disadvantages:

* Cannot satisfy the required access model.
* Insufficient granularity.

#### Option 2: Reapply ACLs manually after every rotation

Advantages:

* Restores permissions.

Disadvantages:

* Operationally fragile.
* Easy to forget.
* Difficult to automate safely.

#### Option 3: Use default ACL inheritance

Advantages:

* Automatic.
* Survives rotation events.
* No manual intervention required.

Disadvantages:

* More complex ACL configuration.

### Decision

Option 3 was selected.

Default ACLs were configured on:

```text
/opt/kijanikiosk/shared/logs
```

and logrotate was configured to create new files using compatible ownership and permissions.

### Reasoning

The selected approach permanently solves the problem instead of repeatedly correcting it.

The solution was validated by:

```bash
sudo logrotate --force /etc/logrotate.d/kijanikiosk
sudo -u kk-api touch /opt/kijanikiosk/shared/logs/test-write.tmp
```

The test passed, proving the access model survives log rotation.

---

# Integration Challenge D

## Package Stability vs System Updates

### Conflict

The audit detected an existing package hold on curl.

The system needed package validation while also respecting administrative decisions that may intentionally freeze package versions.

### Options Considered

#### Option 1: Remove the hold automatically

Advantages:

* Ensures latest package versions.

Disadvantages:

* Overrides administrative intent.
* May introduce unexpected changes.

#### Option 2: Ignore the package hold entirely

Advantages:

* Simple implementation.

Disadvantages:

* Provides no visibility into an important system condition.

#### Option 3: Detect and report the hold while preserving it

Advantages:

* Respects existing system state.
* Provides audit visibility.
* Avoids unintended package changes.

Disadvantages:

* Requires additional logic.

### Decision

Option 3 was selected.

The script detects whether curl is already held and records the condition.

If no hold exists, the script applies the required hold.

### Reasoning

This approach balances operational stability and audit visibility. Existing administrative decisions are preserved while ensuring the project requirements remain satisfied.

---

# Conclusion

Each integration challenge required balancing competing goals rather than simply applying a technical configuration. The final solutions emphasize least privilege, operational reliability, auditability, and maintainability. Firewall controls preserve monitoring access without exposing the payments service, health reporting respects ownership boundaries, ACL inheritance survives log rotation, and package validation respects existing system state. Together these decisions provide a secure and maintainable production foundation while satisfying all project requirements.
