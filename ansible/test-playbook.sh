#!/bin/bash
# =============================================================================
# Test Ansible Playbook Locally
# =============================================================================
# This script validates the Ansible playbook syntax without running it.
# 
# Prerequisites:
#   - Python 3.8+
#   - pip install ansible
#
# Usage:
#   cd ansible
#   ./test-playbook.sh
# =============================================================================

set -e

echo "=========================================="
echo "Ansible Playbook Validation"
echo "=========================================="

# Check if ansible is installed
if ! command -v ansible &> /dev/null; then
    echo "Ansible not found. Installing..."
    pip install 'ansible>=8.0,<9.0'
fi

echo ""
echo "--- Ansible Version ---"
ansible --version

echo ""
echo "--- Checking playbook syntax ---"
ansible-playbook playbooks/deploy.yml --syntax-check -i /dev/null

echo ""
echo "--- Listing tasks (dry run) ---"
ansible-playbook playbooks/deploy.yml --list-tasks -i /dev/null 2>/dev/null || echo "Note: Some warnings are expected without a real inventory"

echo ""
echo "=========================================="
echo "Syntax validation complete!"
echo "=========================================="


