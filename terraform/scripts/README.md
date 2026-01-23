# Terraform Scripts

This directory contains Terraform-specific utility scripts for infrastructure management.

## 🎯 Scope

**This directory is for Terraform-only operations:**
- ✅ Terraform state management
- ✅ Backend configuration
- ✅ Infrastructure-specific utilities
- ❌ No application deployment
- ❌ No Ansible orchestration
- ❌ No full-stack deployment

## 📜 Scripts

### deploy-infrastructure.sh
**Purpose**: Automated Terraform infrastructure deployment
- Complete infrastructure provisioning workflow
- Automatic validation and error handling
- Plan review and approval process
- Output display and logging

**Usage**:
```bash
cd terraform/scripts
./deploy-infrastructure.sh              # Interactive deployment
./deploy-infrastructure.sh --auto-approve  # Skip confirmation
./deploy-infrastructure.sh --plan-only     # Plan only, no apply
./deploy-infrastructure.sh --destroy       # Destroy infrastructure
```

**Features**:
- Automatic Terraform initialization
- Configuration validation
- Plan creation and review
- Interactive or automated apply
- Comprehensive logging to `../terraform-deploy.log`
- Apply summary saved to `../APPLY.txt`
- Destroy summary saved to `../DESTROY.txt`

### migrate-state.sh
**Purpose**: Terraform state migration utility
- Migrates state between backends (local ↔ S3)
- Handles state file transformations
- Validates state integrity
- Creates state backups

**Usage**:
```bash
cd terraform/scripts
./migrate-state.sh
```

**Features**:
- Automatic backend resource validation
- Safe state backup before migration
- Step-by-step migration process
- Rollback support

## 🚀 Quick Start

### For Full Project Deployment
Use the main project script (orchestrates Terraform + Ansible):
```bash
cd /path/to/project-root
./deploy-project.sh
```

### Automated Terraform Deployment
Use the auto-deploy script:
```bash
cd terraform/scripts
./deploy-infrastructure.sh              # Interactive
./deploy-infrastructure.sh --auto-approve  # Automated
```

### Manual Terraform Operations
Work directly with Terraform commands:
```bash
cd terraform
terraform init
terraform plan
terraform apply
terraform output
terraform destroy
```

### State Migration
```bash
cd terraform/scripts
./migrate-state.sh
```

## 🔧 Common Terraform Operations

### First-Time Infrastructure Setup
```bash
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Update Existing Infrastructure
```bash
cd terraform
terraform plan
terraform apply
```

### View Current State
```bash
cd terraform
terraform show
terraform state list
terraform output
```

### Destroy Infrastructure
```bash
cd terraform
terraform destroy
```

## 📊 Project Structure

```
terraform/
├── main.tf                    # Main infrastructure configuration
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output definitions
├── terraform.tfstate          # Current state file
├── terraform-deploy.log       # Deployment log
├── APPLY.txt                  # Apply operation summary
├── DESTROY.txt                # Destroy operation summary
└── scripts/
    ├── README.md              # This file
    ├── deploy-infrastructure.sh  # Auto-deploy script
    └── migrate-state.sh       # State migration utility
```

## 📁 Output Files

Generated in `terraform/` directory:
- **APPLY.txt**: Summary of resources created/updated/deleted during apply
- **DESTROY.txt**: Summary of resources destroyed
- **terraform-deploy.log**: Detailed log with timestamps

## 🔗 Scope Separation

### Terraform Scripts (this directory)
- **Scope**: Infrastructure management only
- **Purpose**: Terraform utilities
- **Operations**: State management, backend configuration

### Main Project Script (`../../deploy-project.sh`)
- **Scope**: Full project orchestration
- **Purpose**: End-to-end deployment
- **Operations**: Terraform → Inventory → Ansible

### Ansible Scripts (`../../ansible/scripts/`)
- **Scope**: Application management
- **Purpose**: Application deployment and configuration
- **Operations**: Deploy apps, check status, manage inventory

## 💡 Best Practices

1. **Infrastructure changes**: Use Terraform commands directly
2. **Full deployment**: Use `deploy-project.sh` in project root
3. **Application updates**: Use Ansible scripts
4. **State migration**: Use `migrate-state.sh`
5. **Always review plans** before applying

## 🔍 Troubleshooting

### State Lock Issues
```bash
cd terraform
terraform force-unlock <LOCK_ID>
```

### Validate Configuration
```bash
cd terraform
terraform validate
terraform fmt -check
terraform fmt  # Auto-format
```

### Backend Issues
```bash
cd terraform/scripts
./migrate-state.sh  # Migrate or fix state
```

### View Detailed State
```bash
cd terraform
terraform state show <resource_address>
terraform state pull > state.json
```

## 📚 Related Documentation

- **Main deployment guide**: [../../README-DEPLOYMENT.md](../../README-DEPLOYMENT.md)
- **Project README**: [../../README.md](../../README.md)
- **Ansible scripts**: [../../ansible/scripts/README.md](../../ansible/scripts/README.md)
- **Scripts summary**: [../../SCRIPTS-SUMMARY.md](../../SCRIPTS-SUMMARY.md)

## ⚠️ Important Notes

1. **Don't use this directory** for full-stack deployment
2. **Use `deploy-project.sh`** for complete deployments
3. **This is Terraform-only** - no Ansible, no app deployment
4. **Direct Terraform commands** are preferred for infrastructure changes

---

**For full project deployment**, see: [README-DEPLOYMENT.md](../../README-DEPLOYMENT.md)
