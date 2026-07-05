#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

echo "==> Running Terraform apply"
cd terraform
terraform apply -auto-approve

echo "==> Checking Terraform idempotency"
terraform plan

echo "==> Collecting Multipass IPs"
API_IP=$(multipass info kijanikiosk-api | awk '/IPv4/{print $2}')
PAYMENTS_IP=$(multipass info kijanikiosk-payments | awk '/IPv4/{print $2}')
LOGS_IP=$(multipass info kijanikiosk-logs | awk '/IPv4/{print $2}')

cd ..

echo "==> Writing Ansible inventory"
cat > ansible/inventory.ini <<INV
[kijanikiosk]
api ansible_host=${API_IP}
payments ansible_host=${PAYMENTS_IP}
logs ansible_host=${LOGS_IP}

[kijanikiosk:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3
INV

echo "==> Inventory created:"
cat ansible/inventory.ini

echo "==> Running Ansible"
ansible-playbook -i ansible/inventory.ini ansible/kijanikiosk.yml
