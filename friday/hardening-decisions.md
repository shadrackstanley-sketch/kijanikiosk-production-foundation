# Hardening Decisions

## Overview

The KijaniKiosk infrastructure was hardened to improve system security, reduce the attack surface, and ensure that services run with the minimum privileges required. Security controls were applied using both Terraform and Ansible to provide a consistent and repeatable deployment.

## Security Measures

* Dedicated system users were created for each service to prevent applications from running as the root user.
* Systemd hardening directives such as `ProtectSystem`, `ProtectHome`, `PrivateTmp`, `PrivateDevices`, `NoNewPrivileges`, and `MemoryDenyWriteExecute` were applied to isolate services and limit access to system resources.
* UFW was configured to allow only SSH access while denying other unsolicited inbound connections.
* Log rotation was configured to prevent log files from consuming excessive disk space.
* Journal persistence was enabled to ensure system logs remain available after reboots for monitoring and troubleshooting.
* Terraform was configured with a remote backend to provide centralized state management and support collaborative infrastructure management.
* Configuration values were separated into variables and templates, making deployments consistent and easier to maintain.

## Validation

The infrastructure was validated by running Terraform and Ansible multiple times. Terraform reported **No changes** on the second execution, while Ansible completed with **changed=0** on all servers, confirming idempotent deployments.

The `kk-payments` service achieved a **systemd-analyze security** score of **0.9 (SAFE)**, exceeding the project requirement of a score below **2.5**.

## Remaining Risks

Although the environment is significantly hardened, it does not fully protect against application-level vulnerabilities, compromised credentials, or network attacks originating from trusted hosts. Regular software updates, continuous monitoring, vulnerability scanning, and secure application development practices remain essential for maintaining a secure production environment.
