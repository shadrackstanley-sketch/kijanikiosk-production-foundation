# Reflection

## 1. Requirement Conflict

The biggest conflict occurred between the Terraform and Ansible stages. Terraform is responsible for provisioning infrastructure, while Ansible requires the server IP addresses before it can connect. Since Multipass assigns IP addresses dynamically, hardcoding them would violate the project requirements.

The solution was to create a pipeline script that automatically retrieves the latest Multipass IP addresses and generates the Ansible inventory before executing the playbook. This removed manual intervention and ensured the pipeline remained reproducible.

---

## 2. Rewriting for Tendo

### Written for Nia

"The infrastructure automatically protects critical services from unnecessary system access, reducing the likelihood that a compromise of one service affects the entire environment."

### Written for Tendo

"The systemd unit applies namespace isolation, capability dropping, ProtectSystem=strict, syscall filtering, and capability bounding to minimise the service attack surface."

The Nia version focuses on business value, while the Tendo version explains the technical implementation.

---

## 3. Weakest Pipeline Handoff

The weakest handoff is the transition between Terraform and Ansible.

Terraform provisions infrastructure, but Ansible depends on accurate inventory information. If IP addresses change or SSH keys are incorrect, the configuration phase immediately fails.

To make this process production-ready, I would integrate Terraform outputs directly into dynamic inventory generation and implement automated validation of SSH connectivity before Ansible execution.
