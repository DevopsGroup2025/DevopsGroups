#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
DEPLOY_SCRIPT="$SCRIPT_DIR/deploy-dynamic.sh"
<<<<<<< HEAD

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
=======
ENV_FILE="$PROJECT_ROOT/env/terraform-output.env"

echo "Exporting Terraform outputs to $ENV_FILE..."
mkdir -p "$PROJECT_ROOT/env"
pushd "$TERRAFORM_DIR" > /dev/null
terraform output -json > "$ENV_FILE.json"
cat <<EOF > "$ENV_FILE"
$(jq -r 'to_entries|map("export " + .key + "=\"" + (.value.value|tostring) + "\"")|.[]' "$ENV_FILE.json")
EOF
popd > /dev/null

# Source the environment variables
set -a
source "$ENV_FILE"
set +a


ACCOUNT_ID=$(echo "$ecr_backend_repository_url" | cut -d'.' -f1)
TAG="latest"

# Defensive: fallback if aws_region is not set
if [ -z "${aws_region:-}" ]; then
  echo "[WARN] aws_region not set from Terraform outputs. Defaulting to eu-west-1."
  aws_region="eu-west-1"
fi

echo "AWS Region: $aws_region"
echo "Backend ECR: $ecr_backend_repository_url"
echo "Frontend ECR: $ecr_frontend_repository_url"
echo "DB Endpoint: $db_endpoint"

echo "Logging into ECR..."
aws ecr get-login-password --region "$aws_region" | \
  docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$aws_region.amazonaws.com"
>>>>>>> 9d57ba9 (fix ansible + terraform)

# ---------------- BACKEND ----------------
echo "Building backend image..."
docker build -t backend "$PROJECT_ROOT/apps/backend"

echo "Tagging backend image..."
<<<<<<< HEAD
docker tag backend "$BACKEND_ECR:$TAG"

echo "Pushing backend image..."
docker push "$BACKEND_ECR:$TAG"
=======
docker tag backend "$ecr_backend_repository_url:$TAG"

echo "Pushing backend image..."
docker push "$ecr_backend_repository_url:$TAG"
>>>>>>> 9d57ba9 (fix ansible + terraform)

# ---------------- FRONTEND ----------------
echo "Building frontend image..."
docker build -t frontend "$PROJECT_ROOT/apps/frontend"

echo "Tagging frontend image..."
<<<<<<< HEAD
docker tag frontend "$FRONTEND_ECR:$TAG"

echo "Pushing frontend image..."
docker push "$FRONTEND_ECR:$TAG"

# ---------------- DEPLOY ----------------
echo "Deploying with Ansible..."
export DB_ENDPOINT="$DB_ENDPOINT"
=======

echo "Pushing frontend image..."
docker push "$ecr_frontend_repository_url:$TAG"

# ---------------- DEPLOY ----------------
echo "Deploying with Ansible..."
export DB_ENDPOINT="$db_endpoint"
export BASTION_PUBLIC_IP="$bastion_public_ip"
export BASTION_KEY_PATH="$bastion_key_path"
export ECR_BACKEND_REPOSITORY_URL="$ecr_backend_repository_url"
export ECR_FRONTEND_REPOSITORY_URL="$ecr_frontend_repository_url"
export DB_SECRET_ARN="$db_secret_arn"
>>>>>>> 9d57ba9 (fix ansible + terraform)

"$DEPLOY_SCRIPT"
