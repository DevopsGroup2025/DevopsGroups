#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
DEPLOY_SCRIPT="$SCRIPT_DIR/deploy-dynamic.sh"

echo "Fetching Terraform outputs..."

pushd "$TERRAFORM_DIR" > /dev/null

AWS_REGION=$(terraform output -raw aws_region 2>/dev/null || echo "eu-west-1")
BACKEND_ECR=$(terraform output -raw ecr_backend_repository_url)
FRONTEND_ECR=$(terraform output -raw ecr_frontend_repository_url)
DB_ENDPOINT=$(terraform output -raw db_endpoint)

popd > /dev/null

ACCOUNT_ID=$(echo "$BACKEND_ECR" | cut -d'.' -f1)
TAG="latest"

echo "AWS Region: $AWS_REGION"
echo "Backend ECR: $BACKEND_ECR"
echo "Frontend ECR: $FRONTEND_ECR"
echo "DB Endpoint: $DB_ENDPOINT"

echo "Logging into ECR..."
aws ecr get-login-password --region "$AWS_REGION" | \
  docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# ---------------- BACKEND ----------------
echo "Building backend image..."
docker build -t backend "$PROJECT_ROOT/apps/backend"

echo "Tagging backend image..."
docker tag backend "$BACKEND_ECR:$TAG"

echo "Pushing backend image..."
docker push "$BACKEND_ECR:$TAG"

# ---------------- FRONTEND ----------------
echo "Building frontend image..."
docker build -t frontend "$PROJECT_ROOT/apps/frontend"

echo "Tagging frontend image..."
docker tag frontend "$FRONTEND_ECR:$TAG"

echo "Pushing frontend image..."
docker push "$FRONTEND_ECR:$TAG"

# ---------------- DEPLOY ----------------
echo "Deploying with Ansible..."
export DB_ENDPOINT="$DB_ENDPOINT"

"$DEPLOY_SCRIPT"
