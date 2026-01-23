# Ansible Deployment Scripts

This directory contains all bash scripts for deploying and managing the full-stack application using Ansible.

## 📜 Scripts

### Main Deployment Scripts

| Script | Size | Purpose |
|--------|------|---------|
| `deploy.sh` | 9.0K | Deploy with static inventory (interactive) |
| `deploy-dynamic.sh` | 13K | Deploy with AWS EC2 dynamic inventory |
| `check-status.sh` | 6.5K | Check application health and PM2 status |
| `update-inventory.sh` | 7.1K | Sync inventory.ini from Terraform outputs |

### Utility Scripts

| Script | Size | Purpose |
|--------|------|---------|
| `test-scripts.sh` | 6.2K | Automated test suite for all scripts |
| `validate-inventory.sh` | 5.8K | Validate inventory configuration |
| `vault-helper.sh` | 7.9K | Ansible Vault helper utilities |

## 🚀 Quick Start

```bash
# Update inventory from Terraform
./update-inventory.sh

# Deploy applications
./deploy.sh

# Check status
./check-status.sh
```

## ✨ Features

All main scripts include:
- ✅ **Fail-safe scripting**: `set -euo pipefail`
- ✅ **Functions**: Modular, reusable code
- ✅ **Logging**: Timestamped logs with levels (INFO/WARN/ERROR/SUCCESS)
- ✅ **Error trapping**: Line numbers on failures
- ✅ **Input validation**: Files, IPs, credentials
- ✅ **Color output**: Visual feedback

## 📊 Log Files

Scripts create log files in the parent ansible/ directory:
- `../deploy.log` - Deployment operations
- `../deploy-dynamic.log` - Dynamic inventory deployments
- `../status-check.log` - Health check history
- `../update-inventory.log` - Inventory updates

## 🔧 Usage Examples

### Static Inventory Deployment
```bash
./update-inventory.sh  # Sync IPs from Terraform
./deploy.sh            # Interactive deployment
./check-status.sh      # Verify health
```

### Dynamic Inventory Deployment
```bash
# Prerequisites (one-time)
ansible-galaxy collection install amazon.aws
pip3 install boto3
aws configure

# Deploy
./deploy-dynamic.sh
```

### Testing
```bash
./test-scripts.sh  # Run automated tests
```

## 📚 Documentation

See parent directory for complete documentation:
- `../README.md` - Complete usage guide
- `../SCRIPT-IMPROVEMENTS.md` - Technical details
- `../QUICK-REFERENCE.md` - Quick command reference

## 🔍 Troubleshooting

Check log files:
```bash
tail -f ../deploy.log
grep ERROR ../deploy.log
```

Validate scripts:
```bash
bash -n *.sh  # Syntax check
./test-scripts.sh  # Full test suite
```

## 💡 Pro Tips

1. Always run from this directory (`ansible/scripts/`)
2. Check logs after operations
3. Use `tail -f` to watch deployments in real-time
4. Run test suite after making changes

---

For detailed documentation, see: [../README.md](../README.md)
