#!/usr/bin/env bash
#
# bootstrap-backend.sh - Create Terraform Backend Infrastructure
#
# This script creates the S3 bucket and DynamoDB table required for
# Terraform remote state management. This is the INDUSTRY-STANDARD
# approach - backend infrastructure is created BEFORE Terraform runs.
#
# Why Bash instead of Terraform?
#   - Avoids chicken-and-egg problem (can't use remote state to create remote state)
#   - One-time setup, rarely changes
#   - Simpler to understand and debug
#   - No state file to manage for the backend itself
#
# Features:
#   - Idempotent (safe to run multiple times)
#   - Creates S3 bucket with versioning and encryption
#   - Creates DynamoDB table for state locking
#   - Applies security best practices (public access block, TLS enforcement)
#   - Generates backend.hcl file for Terraform init
#
# Usage:
#   ./scripts/bootstrap-backend.sh [options]
#
# Options:
#   --bucket NAME       S3 bucket name (default: auto-generated)
#   --table NAME        DynamoDB table name (default: terraform-state-locks)
#   --region REGION     AWS region (default: eu-west-1)
#   --project NAME      Project name for tagging (default: iac)
#   --destroy           Destroy backend resources instead of creating
#   --dry-run           Show what would be done without doing it
#   --help, -h          Show this help message
#
# Examples:
#   ./scripts/bootstrap-backend.sh
#   ./scripts/bootstrap-backend.sh --region us-east-1
#   ./scripts/bootstrap-backend.sh --bucket my-terraform-state
#   ./scripts/bootstrap-backend.sh --destroy
#
# Author: Prince Tetteh Ayiku
# Version: 1.0.0
#

set -euo pipefail

# ============================================================================
# Script Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Default values
AWS_REGION="${AWS_REGION:-eu-west-1}"
PROJECT_NAME="${PROJECT_NAME:-iac}"
DYNAMODB_TABLE="${DYNAMODB_TABLE:-terraform-state-locks}"
S3_BUCKET="${S3_BUCKET:-}"  # Auto-generated if empty
STATE_KEY="iac/terraform.tfstate"

# Flags
DRY_RUN=false
DESTROY_MODE=false
VERBOSE=false

# Colors (disable if not terminal)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    RESET='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' RESET=''
fi

# ============================================================================
# Logging Functions
# ============================================================================

log_info()    { echo -e "${BLUE}[INFO]${RESET} $*"; }
log_success() { echo -e "${GREEN}${BOLD}[SUCCESS]${RESET} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${RESET} $*"; }
log_error()   { echo -e "${RED}${BOLD}[ERROR]${RESET} $*" >&2; }
log_debug()   { [[ "${VERBOSE}" == "true" ]] && echo -e "${CYAN}[DEBUG]${RESET} $*" || true; }

log_step() {
    local step="$1"
    local total="$2"
    shift 2
    echo -e "\n${BOLD}[Step ${step}/${total}]${RESET} $*"
    echo "----------------------------------------"
}

# ============================================================================
# Helper Functions
# ============================================================================

show_help() {
    cat << 'EOF'

â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—
â•‘           Terraform Backend Bootstrap Script                                  â•‘
â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

DESCRIPTION:
    Creates the S3 bucket and DynamoDB table required for Terraform remote
    state management. This is a ONE-TIME setup before running Terraform.

USAGE:
    ./scripts/bootstrap-backend.sh [options]

OPTIONS:
    --bucket NAME       S3 bucket name (default: terraform-state-{project}-{account-id})
    --table NAME        DynamoDB table name (default: terraform-state-locks)
    --region REGION     AWS region (default: eu-west-1)
    --project NAME      Project name for tagging (default: iac)
    --destroy           Destroy backend resources instead of creating
    --dry-run           Show what would be done without doing it
    --verbose, -v       Enable verbose output
    --help, -h          Show this help message

EXAMPLES:
    # Create backend with defaults
    ./scripts/bootstrap-backend.sh

    # Create in specific region
    ./scripts/bootstrap-backend.sh --region us-east-1

    # Create with custom bucket name
    ./scripts/bootstrap-backend.sh --bucket my-company-terraform-state

    # Preview what would be created
    ./scripts/bootstrap-backend.sh --dry-run

    # Destroy backend (CAUTION: deletes all state!)
    ./scripts/bootstrap-backend.sh --destroy

AFTER RUNNING THIS SCRIPT:
    1. Copy backend.hcl.example to backend.hcl (already generated)
    2. Run: terraform init -backend-config=backend.hcl
    3. Run: terraform plan / terraform apply

EOF
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &>/dev/null; then
        log_error "AWS CLI is not installed. Install from: https://aws.amazon.com/cli/"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &>/dev/null; then
        log_error "AWS credentials not configured or expired"
        log_error "Run 'aws configure' or check your AWS_PROFILE"
        exit 1
    fi
    
    # Get account info
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text | tr -d '\r\n')
    AWS_CALLER_ARN=$(aws sts get-caller-identity --query 'Arn' --output text | tr -d '\r\n')
    
    log_info "AWS Account: ${AWS_ACCOUNT_ID}"
    log_debug "Caller ARN: ${AWS_CALLER_ARN}"
    
    # Auto-generate bucket name if not provided
    if [[ -z "${S3_BUCKET}" ]]; then
        S3_BUCKET="terraform-state-${PROJECT_NAME}-${AWS_ACCOUNT_ID}"
        log_info "Auto-generated bucket name: ${S3_BUCKET}"
    fi
    
    log_success "Prerequisites check passed"
}

# ============================================================================
# S3 Bucket Functions
# ============================================================================

bucket_exists() {
    aws s3api head-bucket --bucket "$1" 2>/dev/null
}

create_s3_bucket() {
    log_step 1 4 "Creating S3 Bucket"
    
    if bucket_exists "${S3_BUCKET}"; then
        log_info "Bucket already exists: ${S3_BUCKET}"
        return 0
    fi
    
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY RUN] Would create bucket: ${S3_BUCKET}"
        return 0
    fi
    
    log_info "Creating bucket: ${S3_BUCKET} in ${AWS_REGION}"
    
    # Create bucket (us-east-1 doesn't need LocationConstraint)
    if [[ "${AWS_REGION}" == "us-east-1" ]]; then
        aws s3api create-bucket \
            --bucket "${S3_BUCKET}" \
            --region "${AWS_REGION}"
    else
        aws s3api create-bucket \
            --bucket "${S3_BUCKET}" \
            --region "${AWS_REGION}" \
            --create-bucket-configuration LocationConstraint="${AWS_REGION}"
    fi
    
    log_success "Bucket created: ${S3_BUCKET}"
}

configure_s3_bucket() {
    log_step 2 4 "Configuring S3 Bucket Security"
    
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY RUN] Would configure bucket security settings"
        return 0
    fi
    
    # Enable versioning
    log_info "Enabling versioning..."
    aws s3api put-bucket-versioning \
        --bucket "${S3_BUCKET}" \
        --versioning-configuration Status=Enabled
    
    # Enable server-side encryption (AES-256)
    log_info "Enabling server-side encryption (AES-256)..."
    aws s3api put-bucket-encryption \
        --bucket "${S3_BUCKET}" \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                },
                "BucketKeyEnabled": true
            }]
        }'
    
    # Block all public access
    log_info "Blocking public access..."
    aws s3api put-public-access-block \
        --bucket "${S3_BUCKET}" \
        --public-access-block-configuration '{
            "BlockPublicAcls": true,
            "IgnorePublicAcls": true,
            "BlockPublicPolicy": true,
            "RestrictPublicBuckets": true
        }'
    
    # Apply bucket policy (restrict to account + enforce TLS)
    log_info "Applying bucket policy (account restriction + TLS enforcement)..."
    local bucket_policy
    bucket_policy=$(cat << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EnforceTLSRequestsOnly",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::${S3_BUCKET}",
                "arn:aws:s3:::${S3_BUCKET}/*"
            ],
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        },
        {
            "Sid": "RestrictToAccount",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::${S3_BUCKET}",
                "arn:aws:s3:::${S3_BUCKET}/*"
            ],
            "Condition": {
                "StringNotEquals": {
                    "aws:PrincipalAccount": "${AWS_ACCOUNT_ID}"
                }
            }
        }
    ]
}
EOF
)
    
    aws s3api put-bucket-policy \
        --bucket "${S3_BUCKET}" \
        --policy "${bucket_policy}"
    
    # Add lifecycle rule to clean up old versions (keep 90 days)
    log_info "Adding lifecycle rule for old versions..."
    aws s3api put-bucket-lifecycle-configuration \
        --bucket "${S3_BUCKET}" \
        --lifecycle-configuration '{
            "Rules": [{
                "ID": "CleanupOldVersions",
                "Status": "Enabled",
                "Filter": {},
                "NoncurrentVersionExpiration": {
                    "NoncurrentDays": 90
                }
            }]
        }'
    
    # Tag the bucket
    log_info "Tagging bucket..."
    aws s3api put-bucket-tagging \
        --bucket "${S3_BUCKET}" \
        --tagging "TagSet=[
            {Key=Name,Value=${S3_BUCKET}},
            {Key=Project,Value=${PROJECT_NAME}},
            {Key=Purpose,Value=terraform-state},
            {Key=ManagedBy,Value=bootstrap-script}
        ]"
    
    log_success "Bucket security configured"
}

# ============================================================================
# DynamoDB Functions
# ============================================================================

table_exists() {
    aws dynamodb describe-table --table-name "$1" --region "${AWS_REGION}" &>/dev/null
}

create_dynamodb_table() {
    log_step 3 4 "Creating DynamoDB Table"
    
    if table_exists "${DYNAMODB_TABLE}"; then
        log_info "Table already exists: ${DYNAMODB_TABLE}"
        return 0
    fi
    
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY RUN] Would create table: ${DYNAMODB_TABLE}"
        return 0
    fi
    
    log_info "Creating table: ${DYNAMODB_TABLE}"
    
    aws dynamodb create-table \
        --table-name "${DYNAMODB_TABLE}" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "${AWS_REGION}" \
        --tags \
            Key=Name,Value="${DYNAMODB_TABLE}" \
            Key=Project,Value="${PROJECT_NAME}" \
            Key=Purpose,Value=terraform-state-locking \
            Key=ManagedBy,Value=bootstrap-script
    
    # Wait for table to be active
    log_info "Waiting for table to become active..."
    aws dynamodb wait table-exists \
        --table-name "${DYNAMODB_TABLE}" \
        --region "${AWS_REGION}"
    
    # Enable point-in-time recovery
    log_info "Enabling point-in-time recovery..."
    aws dynamodb update-continuous-backups \
        --table-name "${DYNAMODB_TABLE}" \
        --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true \
        --region "${AWS_REGION}" 2>/dev/null || log_warn "PITR may already be enabled"
    
    log_success "Table created: ${DYNAMODB_TABLE}"
}

# ============================================================================
# Backend Configuration File
# ============================================================================

generate_backend_config() {
    log_step 4 4 "Generating Backend Configuration"
    
    local backend_hcl="${PROJECT_ROOT}/backend.hcl"
    local backend_hcl_example="${PROJECT_ROOT}/backend.hcl.example"
    
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY RUN] Would generate backend.hcl"
        return 0
    fi
    
    # Generate backend.hcl
    cat > "${backend_hcl}" << EOF
# =============================================================================
# Terraform Backend Configuration
# =============================================================================
# Generated by bootstrap-backend.sh on $(date -Iseconds 2>/dev/null || date)
#
# Usage:
#   terraform init -backend-config=backend.hcl
#
# WARNING: This file contains backend configuration and should be in .gitignore
# =============================================================================

bucket         = "${S3_BUCKET}"
key            = "${STATE_KEY}"
region         = "${AWS_REGION}"
dynamodb_table = "${DYNAMODB_TABLE}"
encrypt        = true
EOF

    log_info "Generated: backend.hcl"
    
    # Also generate example file (safe to commit)
    cat > "${backend_hcl_example}" << EOF
# =============================================================================
# Terraform Backend Configuration Example
# =============================================================================
# Copy this file to backend.hcl and update with your values.
# Run: cp backend.hcl.example backend.hcl
#
# Then initialize Terraform:
#   terraform init -backend-config=backend.hcl
# =============================================================================

bucket         = "terraform-state-YOUR_PROJECT-YOUR_ACCOUNT_ID"
key            = "iac/terraform.tfstate"
region         = "eu-west-1"
dynamodb_table = "terraform-state-locks"
encrypt        = true
EOF

    log_info "Generated: backend.hcl.example"
    
    # Ensure backend.hcl is in .gitignore
    if ! grep -q "^backend.hcl$" "${PROJECT_ROOT}/.gitignore" 2>/dev/null; then
        echo -e "\n# Backend configuration (contains bucket names)\nbackend.hcl" >> "${PROJECT_ROOT}/.gitignore"
        log_info "Added backend.hcl to .gitignore"
    fi
    
    log_success "Backend configuration generated"
}

# ============================================================================
# Destroy Functions
# ============================================================================

destroy_backend() {
    echo ""
    echo "â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—"
    echo "â•‘  âš ï¸  WARNING: DESTRUCTIVE OPERATION                                          â•‘"
    echo "â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•"
    echo ""
    echo "This will PERMANENTLY DELETE:"
    echo "  - S3 Bucket: ${S3_BUCKET}"
    echo "  - DynamoDB Table: ${DYNAMODB_TABLE}"
    echo "  - ALL Terraform state history!"
    echo ""
    
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY RUN] Would destroy backend resources"
        return 0
    fi
    
    read -r -p "Type 'destroy-backend' to confirm: " confirm
    if [[ "${confirm}" != "destroy-backend" ]]; then
        log_info "Destruction cancelled"
        exit 0
    fi
    
    echo ""
    
    # Delete S3 bucket
    if bucket_exists "${S3_BUCKET}"; then
        log_info "Deleting S3 bucket: ${S3_BUCKET}"
        
        # Delete all object versions
        log_info "Deleting all object versions..."
        aws s3api list-object-versions \
            --bucket "${S3_BUCKET}" \
            --query 'Versions[*].[Key,VersionId]' \
            --output text 2>/dev/null | while IFS=$'\t' read -r key version_id; do
            if [[ -n "${key}" ]] && [[ "${key}" != "None" ]]; then
                aws s3api delete-object \
                    --bucket "${S3_BUCKET}" \
                    --key "${key}" \
                    --version-id "${version_id}" 2>/dev/null || true
            fi
        done
        
        # Delete delete markers
        aws s3api list-object-versions \
            --bucket "${S3_BUCKET}" \
            --query 'DeleteMarkers[*].[Key,VersionId]' \
            --output text 2>/dev/null | while IFS=$'\t' read -r key version_id; do
            if [[ -n "${key}" ]] && [[ "${key}" != "None" ]]; then
                aws s3api delete-object \
                    --bucket "${S3_BUCKET}" \
                    --key "${key}" \
                    --version-id "${version_id}" 2>/dev/null || true
            fi
        done
        
        # Delete bucket
        aws s3 rb "s3://${S3_BUCKET}" --force 2>/dev/null || true
        log_success "S3 bucket deleted"
    else
        log_info "S3 bucket not found: ${S3_BUCKET}"
    fi
    
    # Delete DynamoDB table
    if table_exists "${DYNAMODB_TABLE}"; then
        log_info "Deleting DynamoDB table: ${DYNAMODB_TABLE}"
        aws dynamodb delete-table \
            --table-name "${DYNAMODB_TABLE}" \
            --region "${AWS_REGION}"
        log_success "DynamoDB table deleted"
    else
        log_info "DynamoDB table not found: ${DYNAMODB_TABLE}"
    fi
    
    # Remove local backend.hcl
    if [[ -f "${PROJECT_ROOT}/backend.hcl" ]]; then
        rm -f "${PROJECT_ROOT}/backend.hcl"
        log_info "Removed backend.hcl"
    fi
    
    log_success "Backend resources destroyed"
}

# ============================================================================
# Summary
# ============================================================================

print_summary() {
    echo ""
    echo "â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—"
    echo "â•‘  âœ… Backend Bootstrap Complete                                               â•‘"
    echo "â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•"
    echo ""
    echo "Resources Created:"
    echo "  S3 Bucket:      ${S3_BUCKET}"
    echo "  DynamoDB Table: ${DYNAMODB_TABLE}"
    echo "  Region:         ${AWS_REGION}"
    echo ""
    echo "Security Features:"
    echo "  âœ“ S3 versioning enabled"
    echo "  âœ“ S3 encryption (AES-256)"
    echo "  âœ“ S3 public access blocked"
    echo "  âœ“ S3 TLS-only connections enforced"
    echo "  âœ“ S3 access restricted to AWS account"
    echo "  âœ“ DynamoDB point-in-time recovery enabled"
    echo ""
    echo "Files Generated:"
    echo "  backend.hcl         - Backend configuration (DO NOT COMMIT)"
    echo "  backend.hcl.example - Example file (safe to commit)"
    echo ""
    echo "â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—"
    echo "â•‘  NEXT STEPS                                                                  â•‘"
    echo "â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•"
    echo ""
    echo "  1. Initialize Terraform with the backend:"
    echo ""
    echo "     terraform init -backend-config=backend.hcl"
    echo ""
    echo "  2. If migrating from local state, answer 'yes' when prompted"
    echo ""
    echo "  3. Run Terraform plan/apply:"
    echo ""
    echo "     terraform plan"
    echo "     terraform apply"
    echo ""
}

# ============================================================================
# Argument Parsing
# ============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --bucket)
                S3_BUCKET="$2"
                shift 2
                ;;
            --table)
                DYNAMODB_TABLE="$2"
                shift 2
                ;;
            --region)
                AWS_REGION="$2"
                shift 2
                ;;
            --project)
                PROJECT_NAME="$2"
                shift 2
                ;;
            --destroy)
                DESTROY_MODE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# ============================================================================
# Main
# ============================================================================

main() {
    parse_args "$@"
    
    echo ""
    echo "â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—"
    echo "â•‘  Terraform Backend Bootstrap                                                 â•‘"
    echo "â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•"
    echo ""
    
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_warn "DRY RUN MODE - No changes will be made"
        echo ""
    fi
    
    check_prerequisites
    
    if [[ "${DESTROY_MODE}" == "true" ]]; then
        destroy_backend
    else
        create_s3_bucket
        configure_s3_bucket
        create_dynamodb_table
        generate_backend_config
        print_summary
    fi
}

main "$@"
