# Deployment Scripts

This directory contains scripts for easy deployment and management of the full-stack application.

## ✨ Script Features

All scripts now include:
- **Functions**: Modular, reusable code for better maintenance
- **Fail-safe scripting**: `set -euo pipefail` for robust error handling
- **Logging**: Automatic logging to .log files with timestamps
- **Error trapping**: Detailed error messages with line numbers
- **Input validation**: Comprehensive checks before operations

## 📁 Files

### Scripts
- **`deploy.sh`** - Main deployment script using static inventory (interactive, with logging)
- **`deploy-dynamic.sh`** - Deployment script using AWS EC2 dynamic inventory
- **`check-status.sh`** - Check application status on all servers
- **`update-inventory.sh`** - Update inventory.ini from Terraform outputs

### Inventory
- **`inventory.ini`** - Static inventory file with backend and frontend IPs
- **`aws_ec2.yml`** - Dynamic inventory configuration (alternative)

### Playbooks
- **`deploy-fullstack.yml`** - Deploy both backend and frontend
- **`deploy-backend.yml`** - Deploy backend only
- **`deploy-frontend.yml`** - Deploy frontend only

## 🚀 Quick Start

### First Time Deployment (Static Inventory)

1. **Update inventory with current IPs:**
   ```bash
   cd scripts
   ./update-inventory.sh
   ```

2. **Deploy everything:**
   ```bash
   ./deploy.sh
   ```

3. **Check status:**
   ```bash
   ./check-status.sh
   ```

### Alternative: Dynamic Inventory Deployment

For AWS-native deployment using EC2 tags:

```bash
cd scripts
./deploy-dynamic.sh
```

**Requirements for dynamic inventory:**
- AWS credentials configured (`aws configure`)
- Python boto3 library (`pip3 install boto3`)
- Ansible AWS collection (`ansible-galaxy collection install amazon.aws`)

## 📊 Log Files

All scripts create log files for troubleshooting:
- `deploy.log` - Deployment activities and errors
- `deploy-dynamic.log` - Dynamic inventory deployment logs
- `status-check.log` - Status check history
- `update-inventory.log` - Inventory update operations

## 📝 Script Details

### deploy.sh

Interactive deployment script with comprehensive error handling and logging.

**Features:**
- Validates inventory and SSH keys exist
- Checks Ansible installation
- Retrieves database endpoint from Terraform
- Validates server IPs from inventory
- Prompts for confirmation before deploying
- Runs the full-stack deployment playbook
- Logs all operations to `deploy.log`
- Shows access URLs on success
- Error trapping with line numbers

**Usage:**
```bash
./deploy.sh
```

**What it does:**
1. Performs pre-flight checks (Ansible, inventory, SSH key)
2. Retrieves and validates database endpoint
3. Extracts and validates server IPs
4. Displays deployment configuration
5. Asks for confirmation
6. Deploys backend and frontend with logging
7. Displays access URLs and status check command

### deploy-dynamic.sh

Dynamic inventory deployment script for AWS-native environments.

**Features:**
- Uses AWS EC2 plugin for dynamic host discovery
- Validates AWS credentials and boto3 library
- Tests dynamic inventory before deployment
- Auto-discovers instances by EC2 tags
- Full logging to `deploy-dynamic.log`
- Region detection from Terraform

**Usage:**
```bash
./deploy-dynamic.sh
```

**Prerequisites:**
```bash
# Install AWS collection
ansible-galaxy collection install amazon.aws

# Install boto3
pip3 install boto3

# Configure AWS credentials
aws configure
```

### check-status.sh

Comprehensive status check with health monitoring and logging.

**Features:**
- Validates Ansible and inventory
- Checks PM2 status on all servers
- Logs all checks to `status-check.log`
- Displays health summary (✓/✗)
- Shows access URLs
- Returns exit code 0 if all healthy, 1 if issues detected

**Usage:**
```bash
./check-status.sh
```

**Output:**
- PM2 process status for backend and frontend
- Health summary with visual indicators
- Access URLs
- Exit code for scripting integration

### update-inventory.sh

Updates `inventory.ini` with current IPs from Terraform with validation and backup.

**Features:**
- Validates Terraform installation and directory
- Retrieves IPs from Terraform outputs
- Validates IP address format
- Creates timestamped backups of existing inventory
- Logs all operations to `update-inventory.log`
- Displays generated inventory

**Usage:**
```bash
./update-inventory.sh
```

**When to use:**
- After running `terraform apply`
- When IP addresses change
- After infrastructure recreation

**Backups:**
Old inventory files are backed up as `inventory.ini.backup.YYYYMMDD_HHMMSS`

## 📋 Manual Deployment

If you prefer to run Ansible commands directly:

### Using inventory.ini
```bash
ansible-playbook deploy-fullstack.yml \
  -i inventory.ini \
  -e "db_endpoint=$(cd ../terraform && terraform output -raw database_address)" \
  -e "db_password=db_password" \
  -e "db_name=notesdb" \
  -e "db_username=dbadmin"
```

### Using dynamic inventory (aws_ec2.yml)
```bash
ansible-playbook deploy-fullstack.yml \
  -e "db_endpoint=$(cd ../terraform && terraform output -raw database_address)" \
  -e "db_password=db_password" \
  -e "db_name=notesdb" \
  -e "db_username=dbadmin"
```

## 🔧 Common Operations

### Check Application Logs

**Backend logs:**
```bash
ansible role_backend -i inventory.ini -m shell \
  -a ". ~/.nvm/nvm.sh && pm2 logs backend --lines 50 --nostream" \
  --become-user=ec2-user
```

**Frontend logs:**
```bash
ansible role_frontend -i inventory.ini -m shell \
  -a ". ~/.nvm/nvm.sh && pm2 logs frontend --lines 50 --nostream" \
  --become-user=ec2-user
```

### Restart Applications

**Restart backend:**
```bash
ansible role_backend -i inventory.ini -m shell \
  -a ". ~/.nvm/nvm.sh && pm2 restart backend" \
  --become-user=ec2-user
```

**Restart frontend:**
```bash
ansible role_frontend -i inventory.ini -m shell \
  -a ". ~/.nvm/nvm.sh && pm2 restart frontend" \
  --become-user=ec2-user
```

### Deploy Individual Components

**Backend only:**
```bash
ansible-playbook deploy-backend.yml \
  -i inventory.ini \
  -e "db_endpoint=$(cd ../terraform && terraform output -raw database_address)" \
  -e "db_password=db_password" \
  -e "db_name=notesdb" \
  -e "db_username=dbadmin"
```

**Frontend only:**
```bash
ansible-playbook deploy-frontend.yml \
  -i inventory.ini \
  -e "db_endpoint=$(cd ../terraform && terraform output -raw database_address)" \
  -e "db_password=db_password" \
  -e "db_name=notesdb" \
  -e "db_username=dbadmin"
```

## 🔑 SSH Key Location

The SSH private key should be located at:
```
./keys/terraform-ansible-webapp-key.pem
```

If your key is elsewhere, update the path in `inventory.ini`.

## 📊 Inventory Structure

The `inventory.ini` file contains:

```ini
[role_backend]
<backend_ip> ansible_user=ec2-user ansible_ssh_private_key_file=./keys/terraform-ansible-webapp-key.pem

[role_frontend]
<frontend_ip> ansible_user=ec2-user ansible_ssh_private_key_file=./keys/terraform-ansible-webapp-key.pem

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
ansible_python_interpreter=/usr/bin/python3
```

## 🆚 Static vs Dynamic Inventory

### Static Inventory (inventory.ini)
✅ Simple and predictable
✅ Works without AWS credentials
✅ Easy to version control (with IPs)
❌ Needs manual updates after infrastructure changes

### Dynamic Inventory (aws_ec2.yml)
✅ Automatically discovers instances
✅ No manual updates needed
✅ Works with auto-scaling
❌ Requires AWS credentials
❌ Slightly slower (API calls)

**Recommendation:** Use static inventory (`inventory.ini`) for stable environments, dynamic inventory for frequently changing infrastructure.

## 🔍 Troubleshooting

### Script Errors

**Check log files first:**
```bash
# View deployment logs
tail -f deploy.log

# View status check logs
cat status-check.log

# View inventory update logs
cat update-inventory.log
```

### Common Issues

**"inventory.ini not found"**
```bash
./update-inventory.sh
```
Check `update-inventory.log` if it fails.

**"SSH key not found"**
Ensure the key exists with correct permissions:
```bash
chmod 400 ./keys/terraform-ansible-webapp-key.pem
```
The script will auto-fix permissions if file exists.

**Deployment hangs or fails**
1. Check `deploy.log` for detailed error messages
2. Verify AWS credentials are valid
3. Verify security groups allow SSH (port 22)
4. Test SSH manually: 
   ```bash
   ssh -i ./keys/terraform-ansible-webapp-key.pem ec2-user@<ip>
   ```

**Dynamic inventory fails**
1. Check AWS credentials: `aws sts get-caller-identity`
2. Verify boto3 installed: `python3 -c "import boto3"`
3. Test inventory manually: `ansible-inventory -i aws_ec2.yml --list`
4. Check `deploy-dynamic.log` for errors

**Applications not responding**
Check PM2 status:
```bash
./check-status.sh
```

View detailed logs:
```bash
ansible all -i inventory.ini -m shell \
  -a ". ~/.nvm/nvm.sh && pm2 logs --lines 20 --nostream" \
  --become-user=ec2-user
```

### Script Exit Codes

All scripts use standard exit codes:
- `0` - Success
- `1` - Error occurred (check log files)

Example for scripting:
```bash
if ./check-status.sh; then
    echo "All systems operational"
else
    echo "Issues detected, check status-check.log"
fi
```

## 📚 Additional Resources

- [DEPLOYMENT.md](../DEPLOYMENT.md) - Comprehensive deployment guide
- [QUICK-START.md](../QUICK-START.md) - Quick reference commands
