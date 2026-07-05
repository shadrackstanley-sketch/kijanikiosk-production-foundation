# Environment Setup

## Host Operating System

| Component | Version |
|----------|---------|
| OS | Ubuntu 24.04 LTS |
| Git | Latest installed via apt |
| Shell | Bash |

---

## Infrastructure Tools

| Tool | Version |
|------|---------|
| Terraform | $(terraform version) |
| Ansible | $(ansible --version | head -1) |
| Multipass | $(multipass version | head -1) |
| MinIO | Local Docker Deployment |
| OpenSSH | Installed |

---

## Virtual Machines

The project provisions and configures the following Ubuntu 22.04 virtual machines using Multipass:

- kijanikiosk-api
- kijanikiosk-payments
- kijanikiosk-logs

Each VM is configured automatically using Ansible.

---

## Terraform

Terraform uses:

- Reusable module architecture
- for_each for server creation
- Remote backend using MinIO
- State stored remotely
- Idempotent configuration

---

## Ansible

Ansible configures:

- Packages
- Service accounts
- Directory structure
- Systemd services
- Firewall
- Journal persistence
- Logrotate
- Service hardening

---

## Verification

Terraform:

- terraform validate ✔
- terraform apply ✔
- terraform plan (No changes) ✔

Ansible:

- ansible ping ✔
- First playbook run ✔
- Second playbook run (changed=0) ✔

---

## Security

The kk-payments systemd service achieved:

```

Overall Exposure Level: 0.9 SAFE

```

which exceeds the project requirement of below 2.5.
