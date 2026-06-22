# KijaniKiosk Hardening Decisions

## Introduction

This document explains the security hardening decisions made during the implementation of the KijaniKiosk Production Server Foundation. The goal was to improve service isolation, reduce attack surface, enforce least-privilege access, and maintain operational reliability. All decisions were evaluated against two criteria:

1. Does the control meaningfully reduce risk?
2. Can the service continue operating correctly after the control is applied?

The final implementation prioritizes practical security improvements while avoiding controls that would break required application functionality.

---

# Security Decision Summary

| Control                      | Implemented | Reason                                                          |
| ---------------------------- | ----------- | --------------------------------------------------------------- |
| Non-root service accounts    | Yes         | Prevents services from running with administrative privileges   |
| Shared application group     | Yes         | Allows controlled resource sharing between services             |
| Environment file permissions | Yes         | Protects sensitive configuration from unauthorized modification |
| ACL-based log access         | Yes         | Provides fine-grained access without over-permissioning         |
| UFW firewall restrictions    | Yes         | Reduces network attack surface                                  |
| Systemd service hardening    | Yes         | Limits process capabilities and filesystem access               |
| Journal persistence          | Yes         | Preserves audit and troubleshooting information                 |
| Log rotation                 | Yes         | Prevents uncontrolled disk consumption                          |
| Health reporting             | Yes         | Improves operational visibility                                 |
| Idempotent provisioning      | Yes         | Ensures safe repeated execution                                 |

---

# User and Group Isolation

A separate service account was created for each major component:

* kk-api
* kk-payments
* kk-logs

Running services under dedicated accounts limits the impact of a service compromise. If one service is exploited, the attacker does not automatically gain access to resources owned by another service.

The shared `kijanikiosk` group was used only where controlled collaboration was required.

This approach follows the principle of least privilege.

---

# Configuration Protection

The `/opt/kijanikiosk/config` directory was secured using restricted ownership and permissions.

Environment files contain operational configuration and may eventually contain secrets such as API keys, database credentials, or tokens.

Allowing write access to service accounts would increase the risk of configuration tampering.

For this reason:

* Root owns configuration files.
* Services receive read-only access where required.
* Other users receive no access.

---

# ACL-Based Log Management

Traditional UNIX permissions were insufficient because different services required different levels of access to the same log directory.

Requirements included:

* kk-api must write logs.
* kk-payments must read logs.
* kk-logs must read and manage logs.

ACLs were selected because they provide precise access control without requiring excessive directory permissions.

Default ACLs were also configured to ensure newly created log files inherit the correct permissions after rotation.

This solved the logrotate inheritance problem while preserving least-privilege access.

---

# Firewall Design

The firewall was configured using a deny-by-default approach.

Allowed traffic:

* SSH (22/tcp)
* HTTP (80/tcp)
* Monitoring subnet access to port 3001
* Loopback access for local service communication

Denied traffic:

* External access to the payments service port

This design minimizes exposed services while still supporting administration and monitoring requirements.

---

# Systemd Hardening

The payments service received the most extensive hardening because it processes financial transactions and represents the highest-value target.

The following controls were applied:

* NoNewPrivileges=true
* ProtectSystem=strict
* ProtectHome=true
* PrivateTmp=true
* PrivateDevices=true
* RestrictRealtime=true
* RestrictAddressFamilies
* ProtectProc=invisible
* ProcSubset=pid
* RestrictNamespaces=true
* PrivateUsers=true
* ProtectClock=true
* ProtectHostname=true
* ProtectControlGroups=true
* ProtectKernelTunables=true
* ProtectKernelModules=true
* RestrictSUIDSGID=true

These controls reduce filesystem exposure, prevent privilege escalation, restrict namespace creation, and limit access to sensitive kernel interfaces.

---

# Journal Persistence

Persistent journaling was enabled because production troubleshooting requires historical logs.

Without persistence:

* Reboots remove operational history.
* Security investigations become more difficult.
* Service failures become harder to diagnose.

A storage limit was configured to prevent uncontrolled growth.

---

# Log Rotation

Log rotation was implemented to manage storage consumption.

Benefits include:

* Controlled disk usage
* Compressed historical logs
* Predictable retention period
* Reduced risk of service disruption due to full disks

The configuration was tested using forced rotation and post-rotation write verification.

---

# Rejected Hardening Options

Several hardening controls were evaluated but intentionally not implemented.

| Control             | Reason Rejected                                                          |
| ------------------- | ------------------------------------------------------------------------ |
| PrivateNetwork=true | Prevents the service from communicating over required network interfaces |
| IPAddressDeny=any   | Blocks legitimate application communication and monitoring traffic       |
| DynamicUser=true    | Creates operational complexity for ACL-managed shared directories        |
| RootDirectory=      | Would require significant application packaging and filesystem redesign  |

These controls may provide additional isolation but would interfere with project requirements or operational functionality.

---

# Honest Gaps and Limitations

The implementation improves security substantially but does not eliminate all risk.

Known limitations include:

1. Services still run within the host filesystem namespace.
2. No mandatory access control framework (SELinux or AppArmor) was implemented.
3. No centralized secrets management solution is deployed.
4. Service binaries are placeholder processes rather than production workloads.
5. TLS termination and certificate management were not implemented.
6. Intrusion detection and endpoint monitoring were not deployed.
7. Automated vulnerability scanning is not included.
8. Security hardening scores remain dependent on application requirements and may require adjustment for future deployments.

These limitations were accepted because they fall outside the scope of the Production Server Foundation project.

---

# Conclusion

The final hardening strategy balances security and operability. Service isolation, ACL-based access control, firewall restrictions, persistent logging, and systemd hardening collectively reduce risk while preserving required functionality. Decisions were made based on measurable security benefit, operational practicality, and the principle of least privilege.

Although additional controls could further reduce exposure, the implemented solution provides a secure and maintainable foundation suitable 
for the current project requirements.
