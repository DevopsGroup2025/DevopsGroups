#!/bin/bash

#==============================================================================
# Full-Stack Application Deployment Script (Dynamic Inventory)
# Description: Deploys backend and frontend using AWS EC2 dynamic inventory
# Usage: ./deploy-dynamic.sh
#==============================================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures
IFS=$'\n\t'        # Set safe Internal Field Separator

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------
# Directory containing this script
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Log file for this script
readonly LOG_FILE="${SCRIPT_DIR}/deploy-dynamic.log"

# Full-stack playbook
readonly PLAYBOOK="${SCRIPT_DIR}/../deploy-fullstack.yml"

# Terraform directory (relative to project root)
readonly TERRAFORM_DIR="$(cd "${SCRIPT_DIR}/../../terraform" && pwd)"

# Dynamic inventory file
readonly INVENTORY_FILE="${SCRIPT_DIR}/../aws_ec2.yml"

readonly VAULT_PASSWORD_FILE="${SCRIPT_DIR}/../.vault_pass"

# Database credentials (modify these as needed)
readonly DB_PASSWORD="db_password"
readonly DB_NAME="notesdb"
readonly DB_USERNAME="dbadmin"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

#------------------------------------------------------------------------------
# Logging Functions
#------------------------------------------------------------------------------
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" | tee -a "$LOG_FILE"
}

log_info() {
    log "INFO" "$@"
}

log_error() {
    log "ERROR" "$@" >&2
}

log_warn() {
    log "WARN" "$@"
}

log_success() {
    log "SUCCESS" "$@"
}

#------------------------------------------------------------------------------
# Utility Functions
#------------------------------------------------------------------------------
print_header() {
    echo -e "${BLUE}=== $* ===${NC}"
    log_info "$*"
}

print_info() {
    echo -e "${BLUE}$*${NC}"
}

print_success() {
    echo -e "${GREEN}$*${NC}"
    log_success "$*"
}

print_error() {
    echo -e "${RED}$*${NC}" >&2
    log_error "$*"
}

print_warn() {
    echo -e "${YELLOW}$*${NC}"
    log_warn "$*"
}

#------------------------------------------------------------------------------
# Validation Functions
#------------------------------------------------------------------------------
check_ansible_installed() {
    if ! command -v ansible-playbook &> /dev/null; then
        print_error "Error: ansible-playbook not found!"
        print_warn "Please install Ansible first: pip install ansible"
        return 1
    fi
    log_info "Ansible found: $(ansible-playbook --version | head -n1)"
    return 0
}

check_aws_credentials() {
    local aws_configured=false
    
    # Check for AWS CLI
    if command -v aws &> /dev/null; then
        if aws sts get-caller-identity &> /dev/null; then
            aws_configured=true
            log_info "AWS credentials configured via AWS CLI"
        fi
    fi
    
    # Check for environment variables
    if [[ -n "${AWS_ACCESS_KEY_ID:-}" && -n "${AWS_SECRET_ACCESS_KEY:-}" ]]; then
        aws_configured=true
        log_info "AWS credentials configured via environment variables"
    fi
    
    # Check for credentials file
    if [[ -f "$HOME/.aws/credentials" ]]; then
        aws_configured=true
        log_info "AWS credentials file found"
    fi
    
    if [[ "$aws_configured" == "false" ]]; then
        print_error "Error: AWS credentials not found!"
        print_warn "Please configure AWS credentials using one of these methods:"
        print_warn "  1. Run: aws configure"
        print_warn "  2. Set environment variables: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY"
        print_warn "  3. Create ~/.aws/credentials file"
        return 1
    fi
    
    return 0
}

check_boto3_installed() {
    if ! python3 -c "import boto3" &> /dev/null; then
        print_error "Error: Python boto3 library not found!"
        print_warn "Dynamic inventory requires boto3. Install it with:"
        print_warn "  pip3 install boto3"
        return 1
    fi
    log_info "boto3 library found"
    return 0
}

check_dynamic_inventory() {
    local inventory_plugins
    inventory_plugins=$(ansible-doc -t inventory -l 2>/dev/null | grep -c "amazon.aws.aws_ec2" || true)
    
    if [[ "$inventory_plugins" -eq 0 ]]; then
        print_error "Error: AWS EC2 dynamic inventory plugin not found!"
        print_warn "Install the amazon.aws collection:"
        print_warn "  ansible-galaxy collection install amazon.aws"
        return 1
    fi
    
    log_info "AWS EC2 dynamic inventory plugin found"
    return 0
}

#------------------------------------------------------------------------------
# Terraform Functions
#------------------------------------------------------------------------------
get_database_endpoint() {
    local db_host
    
    log_info "Retrieving database endpoint from Terraform..."
    
    if [[ ! -d "$TERRAFORM_DIR" ]]; then
        print_error "Error: Terraform directory not found at $TERRAFORM_DIR"
        return 1
    fi
    
    pushd "$TERRAFORM_DIR" > /dev/null || return 1
    
    if ! db_host=$(terraform output -raw database_address 2>/dev/null); then
        popd > /dev/null || true
        print_error "Error: Could not retrieve database endpoint from Terraform"
        print_warn "Make sure Terraform has been applied successfully"
        return 1
    fi
    
    popd > /dev/null || return 1
    
    if [[ -z "$db_host" ]]; then
        print_error "Error: Database endpoint is empty"
        return 1
    fi
    
    echo "$db_host"
    return 0
}

get_aws_region() {
    local region
    
    pushd "$TERRAFORM_DIR" > /dev/null || return 1
    
    if region=$(terraform output -raw aws_region 2>/dev/null); then
        popd > /dev/null || return 1
        echo "$region"
        return 0
    fi
    
    popd > /dev/null || return 1
    
    # Fallback to default region
    echo "eu-west-1"
    log_warn "Could not get AWS region from Terraform, using default: eu-west-1"
    return 0
}

# Ensure jq is installed on Amazon Linux
ensure_jq() {
    if command -v jq >/dev/null 2>&1; then
        print_info "jq is already installed"
        return 0
    fi

    print_warn "jq not found, installing..."

    if command -v yum >/dev/null 2>&1; then
        sudo yum install -y jq
    elif command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y jq
    else
        print_error "Error: Could not determine package manager to install jq"
        return 1
    fi
}


#------------------------------------------------------------------------------
# Inventory Functions
#------------------------------------------------------------------------------
test_dynamic_inventory() {
    ensure_jq || return 1

    print_info "Testing dynamic inventory connection..."
    log_info "Listing hosts from dynamic inventory"

    local inventory_json backend_count frontend_count

    if ! inventory_json=$(ansible-inventory -i "$INVENTORY_FILE" --vault-password-file "$VAULT_PASSWORD_FILE" --list 2>/dev/null); then
        print_error "Failed to list hosts from dynamic inventory"
        print_warn "Check AWS credentials, permissions, inventory plugin config, and vault password file"
        return 1
    fi

    backend_count=$(echo "$inventory_json" | jq -r '.role_backend.hosts | length // 0')
    frontend_count=$(echo "$inventory_json" | jq -r '.role_frontend.hosts | length // 0')

    print_success "Dynamic inventory working!"
    print_info "  Backend instances: $backend_count"
    print_info "  Frontend instances: $frontend_count"
    
    if [[ "$backend_count" -eq 0 || "$frontend_count" -eq 0 ]]; then
        print_warn "Warning: Some instance groups are empty"
        print_warn "Verify EC2 instance tags (Role, Project, Environment)"
        return 1
    fi

    log_info "Dynamic inventory test passed (backend: $backend_count, frontend: $frontend_count)"
    return 0
}

#------------------------------------------------------------------------------
# Deployment Functions
#------------------------------------------------------------------------------
display_deployment_info() {
    local db_host="$1"
    local aws_region="$2"
    
    echo
    print_header "Deployment Configuration"
    print_info "  Inventory: ${GREEN}Dynamic (aws_ec2.yml)${NC}"
    print_info "  Playbook: ${GREEN}$PLAYBOOK${NC}"
    print_info "  AWS Region: ${GREEN}$aws_region${NC}"
    print_info "  Database Endpoint: ${GREEN}$db_host${NC}"
    print_info "  Database Name: ${GREEN}$DB_NAME${NC}"
    print_info "  Database User: ${GREEN}$DB_USERNAME${NC}"
    echo
}

confirm_deployment() {
    print_warn "Do you want to proceed with the deployment? (yes/no)"
    read -r CONFIRM
    
    if [[ "$CONFIRM" != "yes" ]]; then
        print_warn "Deployment cancelled by user."
        return 1
    fi
    
    log_info "Deployment confirmed by user"
    return 0
}

run_deployment() {
    local db_host="$1"
    
    echo
    print_header "Starting Deployment"
    echo
    
    log_info "Executing Ansible playbook: $PLAYBOOK"
    log_info "Using dynamic inventory: aws_ec2.yml"
    
    # Set AWS region for dynamic inventory
    export AWS_REGION="${AWS_REGION:-eu-west-1}"
    
    if ansible-playbook "$PLAYBOOK" -i "$INVENTORY_FILE" --vault-password-file "$VAULT_PASSWORD_FILE"; then
        return 0
    else
        return 1
    fi
}

get_deployed_ips() {
    log_info "Retrieving deployed instance IPs"
    
    local backend_ip frontend_ip
    
    backend_ip=$(ansible-inventory -i aws_ec2.yml --list 2>/dev/null | \
        jq -r '._meta.hostvars | to_entries[] | select(.value.tags.role == "backend") | .value.public_ip_address' 2>/dev/null | head -n1)
    
    frontend_ip=$(ansible-inventory -i aws_ec2.yml --list 2>/dev/null | \
        jq -r '._meta.hostvars | to_entries[] | select(.value.tags.role == "frontend") | .value.public_ip_address' 2>/dev/null | head -n1)
    
    echo "$backend_ip|$frontend_ip"
}

display_success_info() {
    local ips
    ips=$(get_deployed_ips)
    local backend_ip="${ips%%|*}"
    local frontend_ip="${ips##*|}"
    
    echo
    print_header "Deployment Successful!"
    echo
    print_success "Access your applications:"
    
    if [[ -n "$frontend_ip" && "$frontend_ip" != "null" ]]; then
        print_info "  Frontend: ${GREEN}http://$frontend_ip:3000${NC}"
    else
        print_warn "  Frontend: IP not available yet (check AWS console)"
    fi
    
    if [[ -n "$backend_ip" && "$backend_ip" != "null" ]]; then
        print_info "  Backend API: ${GREEN}http://$backend_ip:3001${NC}"
    else
        print_warn "  Backend: IP not available yet (check AWS console)"
    fi
    
    echo
    print_info "To check status, run: ansible all -i aws_ec2.yml -m shell -a '. ~/.nvm/nvm.sh && pm2 status' --become-user=ec2-user"
    echo
}

#------------------------------------------------------------------------------
# Main Function
#------------------------------------------------------------------------------
main() {
    # Initialize log file
    log_info "========================================="
    log_info "Starting dynamic inventory deployment"
    log_info "========================================="
    
    print_header "Full-Stack Application Deployment (Dynamic Inventory)"
    echo
    
    # Validations
    check_ansible_installed || exit 1
    check_aws_credentials || exit 1
    check_boto3_installed || exit 1
    check_dynamic_inventory || exit 1
    
    # Test dynamic inventory
    test_dynamic_inventory || {
        print_error "Dynamic inventory test failed"
        exit 1
    }
    
    echo
    
    # Get database endpoint
    local db_host
    print_info "Retrieving database information..."
    if ! db_host=$(get_database_endpoint); then
        exit 1
    fi
    log_info "Database endpoint: $db_host"
    
    # Get AWS region
    local aws_region
    aws_region=$(get_aws_region)
    export AWS_REGION="$aws_region"
    
    # Display information and confirm
    display_deployment_info "$db_host" "$aws_region"
    confirm_deployment || exit 0
    
    # Run deployment
    if run_deployment "$db_host"; then
        display_success_info
        log_info "Deployment completed successfully"
        exit 0
    else
        echo
        print_error "=== Deployment Failed! ==="
        print_warn "Check the error messages above and the log file: $LOG_FILE"
        log_error "Deployment failed"
        exit 1
    fi
}

#------------------------------------------------------------------------------
# Script Entry Point
#------------------------------------------------------------------------------
# Trap errors and cleanup
trap 'log_error "Script failed at line $LINENO"' ERR

# Run main function
main "$@"
