#!/bin/bash
set -e

echo "=============================================="
echo " Enterprise Security Compliance - Full Run"
echo " DEV + PROD"
echo "=============================================="

echo
echo "[1/2] DEV - CIS Level 1"
ansible-playbook -i inventories/dev/hosts.yml site.yml
echo "DEV complete"

echo
echo "[2/2] PROD - CIS Level 2 + STIG"
ansible-playbook -i inventories/prod/hosts.yml site.yml
echo "PROD complete"

echo
echo "=============================================="
echo " DEV + PROD COMPLETE"
echo " Reports: /tmp/compliance-reports/"
echo "=============================================="
