# Step-by-Step Deployment Guide

This guide walks you through deploying the containerized multi-service web application using GitHub Actions.

---

## Prerequisites

Before you begin, ensure you have:

- [ ] A GitHub account
- [ ] An AWS account with appropriate permissions
- [ ] AWS CLI installed locally (for initial setup)
- [ ] Git installed locally

---

## Step 1: Create a GitHub Repository

### 1.1 Create a new repository on GitHub

1. Go to [GitHub](https://github.com) and log in
2. Click the **+** icon in the top right → **New repository**
3. Name your repository (e.g., `notes-app-devops`)
4. Choose **Private** or **Public**
5. **DO NOT** initialize with README (you already have one)
6. Click **Create repository**

### 1.2 Push your local code to GitHub

Open a terminal in your project directory and run:

```bash
# Initialize git if not already done
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: Containerized multi-service web application"

# Add the remote repository (replace with your repo URL)
git remote add origin https://github.com/YOUR_USERNAME/notes-app-devops.git

# Push to main branch
git branch -M main
git push -u origin main
```

---

## Step 2: Configure GitHub Secrets

GitHub Secrets store sensitive information needed for deployment. You need to add these in your repository settings.

### 2.1 Navigate to Secrets Settings

1. Go to your GitHub repository
2. Click **Settings** (tab at the top)
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret**

### 2.2 Add Required Secrets

Add each of these secrets one by one:

| Secret Name | Description | Required | Example Value |
|-------------|-------------|----------|---------------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key | ✅ Yes | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key | ✅ Yes | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `AWS_SESSION_TOKEN` | Session token (for temporary credentials) | ⚠️ Only if using SSO/temporary creds | `FwoGZXIvYXdzE...` |
| `DB_PASSWORD` | Database password for production | ✅ Yes | `YourSecurePassword123!` |

### 2.3 When Do You Need AWS_SESSION_TOKEN?

You need `AWS_SESSION_TOKEN` if you're using:
- **AWS SSO** (Single Sign-On)
- **AWS IAM Identity Center**
- **Assumed roles** (`aws sts assume-role`)
- **Temporary credentials** from any source

You **DON'T** need it if you're using:
- **Long-term IAM user credentials** (Access Key + Secret Key only)

### 2.5 How to Get AWS Credentials

#### Option A: Long-term IAM User Credentials (Simpler)

If you don't have AWS credentials:

1. Log into [AWS Console](https://console.aws.amazon.com)
2. Go to **IAM** → **Users** → **Your User**
3. Click **Security credentials** tab
4. Click **Create access key**
5. Choose **Command Line Interface (CLI)**
6. Copy the Access Key ID and Secret Access Key

With this option, you only need:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

#### Option B: Temporary Credentials (AWS SSO / Assumed Roles)

If you're using AWS SSO or temporary credentials:

```bash
# Login with AWS SSO
aws sso login --profile your-profile

# Get temporary credentials
aws configure export-credentials --profile your-profile
```

This will output:
```json
{
  "AccessKeyId": "ASIA...",
  "SecretAccessKey": "...",
  "SessionToken": "...",
  "Expiration": "2026-01-23T..."
}
```

Add all three values to GitHub Secrets:
- `AWS_ACCESS_KEY_ID` → AccessKeyId
- `AWS_SECRET_ACCESS_KEY` → SecretAccessKey
- `AWS_SESSION_TOKEN` → SessionToken

⚠️ **Important**: Session tokens expire! You'll need to update the `AWS_SESSION_TOKEN` secret when it expires (typically 1-12 hours depending on your configuration).

#### Option C: Use OIDC (Recommended for Production)

For production, consider using GitHub OIDC to assume an AWS role without storing credentials. This requires additional AWS setup but is more secure.

**Required AWS Permissions:**
- EC2 (create/manage instances)
- VPC (create/manage networks)
- RDS (create/manage databases)
- IAM (limited - for instance profiles)
- S3 (for Terraform state)

---

## Step 3: Configure GitHub Variables (Optional)

Variables are for non-sensitive configuration.

### 3.1 Add Repository Variables

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click the **Variables** tab
3. Click **New repository variable**

| Variable Name | Description | Default Value |
|---------------|-------------|---------------|
| `AWS_REGION` | AWS region to deploy to | `eu-west-1` |

---

## Step 4: Set Up Terraform Backend (One-Time Setup)

Before the first deployment, you need to create an S3 bucket for Terraform state.

### 4.1 Create S3 Bucket for Terraform State

Run these commands locally (one-time setup):

```bash
# Set your AWS credentials
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="eu-west-1"

# Navigate to terraform backend setup
cd terraform/backend-setup

# Initialize and apply
terraform init
terraform apply -auto-approve
```

### 4.2 Update Backend Configuration

After creating the bucket, update `terraform/backend.tf` with your bucket name:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket-name"
    key            = "notes-app/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

---

## Step 5: Create GitHub Environments (Optional but Recommended)

Environments allow you to add approval gates and environment-specific secrets.

### 5.1 Create Staging Environment

1. Go to **Settings** → **Environments**
2. Click **New environment**
3. Name it `staging`
4. Click **Configure environment**
5. (Optional) Add required reviewers for manual approval
6. Click **Save protection rules**

### 5.2 Create Production Environment

1. Click **New environment**
2. Name it `production`
3. Click **Configure environment**
4. **Recommended**: Add required reviewers
5. **Recommended**: Add deployment branch rule (only `main`)
6. Click **Save protection rules**

---

## Step 6: Trigger the Deployment

### 6.1 Automatic Trigger (Push to main)

The workflow automatically runs when you push to `main` or `develop`:

```bash
# Make a change
echo "# Deployment test" >> test.md

# Commit and push
git add .
git commit -m "Trigger deployment"
git push origin main
```

### 6.2 Manual Trigger

You can also trigger the workflow manually:

1. Go to your repository on GitHub
2. Click **Actions** tab
3. Select **CI/CD Pipeline** workflow
4. Click **Run workflow**
5. Select the branch and environment
6. Click **Run workflow**

---

## Step 7: Monitor the Deployment

### 7.1 View Workflow Progress

1. Go to **Actions** tab in your repository
2. Click on the running workflow
3. You'll see the pipeline stages:

```
┌─────────────────┐
│   lint-test     │  ← Code quality checks
└────────┬────────┘
         │
┌────────▼────────┐
│     build       │  ← Build Docker images
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
┌───▼───┐ ┌───▼───────────┐
│security│ │integration-test│  ← Run in parallel
│ scan   │ │               │
└───┬───┘ └───────┬───────┘
    │             │
    └──────┬──────┘
           │
    ┌──────▼──────┐
    │    push     │  ← Push images to registry
    └──────┬──────┘
           │
    ┌──────▼──────┐
    │   deploy    │  ← Deploy to AWS
    └─────────────┘
```

### 7.2 View Logs

Click on any job to see detailed logs:
- Build logs show Docker image creation
- Integration test logs show service health checks
- Deploy logs show Terraform and Ansible output

---

## Step 8: Verify Deployment

After successful deployment:

### 8.1 Get the Application URL

The deployment summary will show the URLs:
1. Click on the completed **deploy** job
2. Scroll to the **Deployment Summary** step
3. You'll see the Frontend and Backend URLs

### 8.2 Test the Application

```bash
# Replace with your actual URL
APP_URL="http://your-frontend-ip"

# Test frontend
curl $APP_URL

# Test backend health
curl $APP_URL/health

# Test API
curl $APP_URL/notes
```

---

## Step 9: View Deployed Resources

### 9.1 AWS Console

1. Log into [AWS Console](https://console.aws.amazon.com)
2. Check these services:
   - **EC2**: View running instances (frontend, backend)
   - **RDS**: View database instance
   - **VPC**: View network configuration

### 9.2 SSH into Instances (if needed)

```bash
# Download the SSH key from Ansible keys directory
# The key is generated by Terraform

# SSH to backend
ssh -i ansible/keys/terraform-ansible-webapp-key.pem ec2-user@<backend-ip>

# SSH to frontend
ssh -i ansible/keys/terraform-ansible-webapp-key.pem ec2-user@<frontend-ip>
```

---

## Workflow Stages Explained

### Stage 1: Lint & Test
- Runs code quality checks on backend and frontend
- Executes unit tests (if available)
- Runs in parallel for both services

### Stage 2: Build
- Builds Docker images using multi-stage Dockerfiles
- Uses GitHub Actions cache for faster builds
- Saves images as artifacts for later stages

### Stage 3: Security Scan
- Scans Docker images with Trivy
- Reports vulnerabilities (CRITICAL, HIGH)
- Currently set to warn only (not block)

### Stage 4: Integration Test
- Starts all services with Docker Compose
- Tests service health endpoints
- Tests API functionality
- Verifies data persistence

### Stage 5: Push Images
- Pushes images to GitHub Container Registry
- Only runs on `main` and `develop` branches
- Tags images with commit SHA and `latest`

### Stage 6: Deploy
- Runs Terraform to provision/update AWS infrastructure
- Runs Ansible to deploy application
- Only runs on `main` branch

---

## Troubleshooting

### Workflow Failed at lint-test
```
Error: npm run lint failed
```
**Solution**: Check your code for linting errors locally:
```bash
cd apps/backend && npm run lint
cd apps/frontend && npm run lint
```

### Workflow Failed at build
```
Error: Docker build failed
```
**Solution**: Test the build locally:
```bash
docker build -t test-backend ./apps/backend
docker build -t test-frontend ./apps/frontend
```

### Workflow Failed at integration-test
```
Error: Service health check failed
```
**Solution**: Run docker-compose locally:
```bash
docker compose up -d
docker compose logs
```

### Workflow Failed at deploy
```
Error: Terraform apply failed
```
**Solution**: 
1. Check AWS credentials are correct
2. Check you have required permissions
3. Run Terraform locally to see detailed errors:
```bash
cd terraform
terraform init
terraform plan
```

### AWS Credentials Invalid
```
Error: The security token included in the request is invalid
```
**Solution**:
1. Verify secrets are set correctly in GitHub
2. Generate new AWS access keys
3. Update the secrets in GitHub

---

## Quick Reference Commands

### Local Development
```bash
# Start all services locally
docker compose up -d

# View logs
docker compose logs -f

# Stop services
docker compose down

# Rebuild and restart
docker compose up -d --build
```

### Git Commands
```bash
# Push changes to trigger deployment
git add .
git commit -m "Your message"
git push origin main

# Create feature branch
git checkout -b feature/new-feature
git push origin feature/new-feature
```

### AWS CLI Commands
```bash
# List EC2 instances
aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId,State.Name,PublicIpAddress]'

# List RDS instances
aws rds describe-db-instances --query 'DBInstances[].[DBInstanceIdentifier,DBInstanceStatus,Endpoint.Address]'
```

---

## Cost Considerations

Running this infrastructure on AWS will incur costs:

| Resource | Approximate Cost |
|----------|------------------|
| EC2 t3.micro (2x) | ~$15/month |
| RDS db.t3.micro | ~$15/month |
| NAT Gateway (if enabled) | ~$32/month |
| Data Transfer | Variable |

**Total estimated**: ~$30-60/month (without NAT Gateway)

### To Minimize Costs:
1. Stop instances when not in use
2. Use smaller instance types for dev/staging
3. Disable NAT Gateway if not needed
4. Set up billing alerts in AWS

---

## Next Steps

After successful deployment:

1. [ ] Set up a custom domain name
2. [ ] Configure HTTPS with SSL certificate
3. [ ] Set up monitoring and alerting
4. [ ] Configure backup retention policies
5. [ ] Set up log aggregation
6. [ ] Implement blue-green deployments

---

## Support

If you encounter issues:

1. Check the [GitHub Actions logs](../../actions)
2. Review the [README.md](README.md) for architecture details
3. Check AWS CloudWatch logs for application errors
