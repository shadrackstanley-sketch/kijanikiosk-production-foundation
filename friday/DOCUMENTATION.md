# KijaniKiosk Infrastructure as Code (IaC) Documentation

## Overview

This project implements a complete Infrastructure as Code (IaC) solution for the KijaniKiosk staging environment using Terraform and Ansible. The infrastructure is provisioned automatically, configured consistently, and secured using systemd hardening and firewall rules.

## Technologies Used

- Terraform
- Ansible
- Multipass
- MinIO
- Ubuntu 22.04 LTS
- Git

## Infrastructure

The environment consists of three virtual machines:

- kijanikiosk-api
- kijanikiosk-payments
- kijanikiosk-logs

Terraform uses a reusable module with `for_each` to provision and manage the servers.

## Configuration

Ansible configures each server by:

- Installing required packages
- Creating service accounts
- Creating application directories
- Deploying systemd service files
- Configuring UFW firewall
- Enabling journal persistence
- Configuring log rotation
- Applying systemd security hardening

Configuration values are managed using `group_vars`, `host_vars`, and Jinja2 templates.

## Automation Pipeline

The deployment workflow is automated through `pipeline.sh`, which:

1. Executes Terraform.
2. Retrieves the latest Multipass IP addresses.
3. Generates the Ansible inventory.
4. Executes the Ansible playbook.

## Validation

The deployment was successfully validated by:

- Running `terraform validate`
- Successfully applying the Terraform configuration
- Confirming `terraform plan` reports **No changes**
- Successfully executing the Ansible playbook
- Confirming a second Ansible run reports **changed=0**

## Security

Security controls implemented include:

- Dedicated service accounts
- Systemd service hardening
- Capability restrictions
- Filesystem protection
- Firewall configuration
- Journal persistence
- Log rotation

The `kk-payments` service achieved a **systemd-analyze security** score of **0.9 (SAFE)**, exceeding the project requirement of a score below **2.5**.

## Conclusion

This project demonstrates a fully automated, secure, and reproducible Infrastructure as Code pipeline. Terraform provisions the infrastructure, Ansible configures the servers, and the deployment can be executed repeatedly without introducing configuration drift.
