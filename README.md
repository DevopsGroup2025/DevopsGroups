# Containerized Multi-Service Web Application with AWS Infrastructure

## Project Overview

This project demonstrates a **production-ready, containerized multi-service web application** deployed on **AWS** using **Infrastructure as Code (IaC)**. The system follows enterprise DevOps practices with automated CI/CD, security scanning, and infrastructure automation.

### Technology Stack

**Application Layer:**
- **Backend**: NestJS (TypeScript) REST API
- **Frontend**: Next.js (React) with Server-Side Rendering
- **Database**: PostgreSQL (RDS)
- **Reverse Proxy**: Nginx

**Infrastructure & DevOps:**
- **IaC**: Terraform (AWS infrastructure provisioning)
- **Configuration Management**: Ansible (application deployment)
- **CI/CD**: GitHub Actions (automated build, test, deploy)
- **Container Registry**: AWS ECR (Elastic Container Registry)
- **Cloud Platform**: AWS (VPC, EC2, RDS, ECR, IAM)

---

## Architecture

### AWS Infrastructure Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        AWS Cloud (eu-west-1)                                  │
│  ┌───────────────────────────────────────────────────────────────────────┐    │
│  │                      VPC: 10.0.0.0/16                                │    │
│  │                                                                       │    │
│  │  ┌───────────────────────────────────────────────────────────────┐   │    │
│  │  │              PUBLIC SUBNET (10.0.1.0/24)                       │   │    │
│  │  │  ┌─────────────┐              ┌─────────────┐                 │   │    │
│  │  │  │  Internet   │              │     NAT     │                 │   │    │
│  │  │  │  Gateway     │              │   Gateway   │                 │   │    │
│  │  │  └──────┬──────┘              └──────┬──────┘                 │   │    │
│  │  │         │                            │                        │   │    │
│  │  │         └──────────┐         ┌────────┘                        │   │    │
│  │  │                    ▼         ▼                                 │   │    │
│  │  │            ┌─────────────────────┐                             │   │    │
│  │  │            │   Bastion Host      │                             │   │    │
│  │  │            │   (Nginx Proxy)     │                             │   │    │
│  │  │            │   Public IP         │                             │   │    │
│  │  │            └──────────┬──────────┘                             │   │    │
│  │  └───────────────────────┼───────────────────────────────────────┘   │    │
│  │                          │                                             │    │
│  │  ┌───────────────────────┼───────────────────────────────────────┐   │    │
│  │  │              PRIVATE SUBNETS                                    │   │    │
│  │  │                          │                                       │   │    │
│  │  │         ┌────────────────┴────────────────┐                   │   │    │
│  │  │         │                                  │                   │   │    │
│  │  │  ┌──────▼───────┐              ┌──────▼───────┐                │   │    │
│  │  │  │   Frontend    │              │   Backend    │                │   │    │
│  │  │  │   (Next.js)   │              │  (NestJS)    │                │   │    │
│  │  │  │   Port 3000   │              │  Port 3001   │                │   │    │
│  │  │  │ Private IP    │              │ Private IP   │                │   │    │
│  │  │  └──────────────┘              └──────┬───────┘                │   │    │
│  │  │                                        │                          │   │    │
│  │  │                              ┌─────────▼─────────┐                │   │    │
│  │  │                              │   RDS PostgreSQL │                │   │    │
│  │  │                              │   Port 5432      │                │   │    │
│  │  │                              │   Multi-AZ        │                │   │    │
│  │  │                              └──────────────────┘                │   │    │
│  │  └──────────────────────────────────────────────────────────────────┘   │    │
│  └───────────────────────────────────────────────────────────────────────┘    │
│                                                                                │
│  ┌───────────────────────────────────────────────────────────────────────┐    │
│  │                    AWS ECR (Container Registry)                       │    │
│  │  • terraform-ansible-webapp-backend                                   │    │
│  │  • terraform-ansible-webapp-frontend                                  │    │
│  │  • terraform-ansible-webapp-proxy                                     │    │
│  └───────────────────────────────────────────────────────────────────────┘    │
└───────────────────────────────────────────────────────────────────────────────┘
                              ▲
                              │
                    ┌─────────┴─────────┐
                    │  GitHub Actions   │
                    │   CI/CD Pipeline  │
                    └───────────────────┘
```

### Network Flow

```
Internet
   │
   │ HTTP/HTTPS (Port 80/443)
   ▼
Internet Gateway
   │
   ▼
Bastion Host (Nginx Proxy)
   │                    │
   │ /api/*, /health    │ / (all other routes)
   ▼                    ▼
Backend (NestJS)    Frontend (Next.js)
   │                    │
   │                    │ API calls
   │                    ▼
   │              Backend (NestJS)
   │                    │
   │                    │ PostgreSQL
   │                    ▼
   └─────────────────► RDS Database
```

### Security Architecture

- **3-Tier Security Model**:
  - **Public Tier**: Bastion/Nginx (ALB Security Group) - HTTP/HTTPS/SSH from Internet
  - **Application Tier**: Frontend/Backend (Application Security Group) - Ports 3000, 3001, 22 from Public Tier only
  - **Data Tier**: RDS (Database Security Group) - Port 5432 from Application Tier only

- **Network Isolation**:
  - Private subnets have no direct internet access
  - Outbound traffic via NAT Gateway only
  - Database in private subnet, no public access

---

## Project Structure

```
DevopsGroups/
├── .github/
│   └── workflows/
│       └── ci-cd.yml              # GitHub Actions CI/CD pipeline
├── apps/
│   ├── backend/                   # NestJS backend application
│   │   ├── src/
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   └── tsconfig.json
│   └── frontend/                  # Next.js frontend application
│       ├── src/
│       ├── Dockerfile
│       ├── package.json
│       └── next.config.js
├── terraform/                     # Infrastructure as Code
│   ├── main.tf                    # Main Terraform configuration
│   ├── variables.tf               # Variable definitions
│   ├── outputs.tf                 # Output values
│   ├── modules/
│   │   ├── vpc/                   # VPC, subnets, NAT Gateway, IGW
│   │   ├── compute/               # EC2 instances (Bastion, Frontend, Backend)
│   │   ├── rds/                   # RDS PostgreSQL database
│   │   ├── ecr/                   # ECR repositories
│   │   ├── iam/                   # IAM roles and policies
│   │   ├── networking/            # Security groups
│   │   └── keys/                  # SSH key pairs
│   └── scripts/
│       └── destroy-ecr.ps1        # Helper script for ECR cleanup
├── ansible/                       # Configuration Management
│   ├── playbooks/
│   │   └── deploy.yml             # Main deployment playbook
│   ├── inventory/
│   │   └── hosts.ini              # Auto-generated by Terraform
│   ├── ansible.cfg                # Ansible configuration
│   └── test-playbook.sh           # Local playbook validation
├── docker-compose.yml           # Local development orchestration
├── docker-compose.test.yml       # Integration test configuration
├── env.example                    # Environment variables template
└── README.md                      # This file
```

---

## Quick Start

### Local Development (Docker Compose)

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd DevopsGroups
   ```

2. **Create environment file**
   ```bash
   cp env.example .env
   # Edit .env with your preferred settings
   ```

3. **Start all services**
   ```bash
   docker compose up -d
   ```

4. **Access the application**
   - Frontend: http://localhost
   - Backend API: http://localhost/api/notes
   - Health Check: http://localhost/health

### AWS Deployment

#### Prerequisites

- **AWS Account** with appropriate permissions
- **Terraform** >= 1.5.0
- **Ansible** >= 8.0
- **AWS CLI** configured (`aws configure`)
- **SSH Key Pair** (or let Terraform generate one)

#### Step 1: Configure Terraform Variables

Edit `terraform/terraform.tfvars` or set environment variables:

```hcl
project_name = "terraform-ansible-webapp"
aws_region   = "eu-west-1"
environment  = "dev"

# VPC Configuration
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

# Database Configuration
db_name           = "notesdb"
db_username       = "dbadmin"
db_password       = "your-secure-password"
db_instance_class = "db.t3.micro"
```

#### Step 2: Provision AWS Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Review the execution plan
terraform plan

# Apply infrastructure
terraform apply
```

This creates:
- VPC with public/private subnets across 2 AZs
- Internet Gateway and NAT Gateway
- Security Groups (3-tier architecture)
- EC2 instances (Bastion, Frontend, Backend)
- RDS PostgreSQL database
- ECR repositories
- IAM roles and policies
- SSH key pair

#### Step 3: Deploy Application with Ansible

```bash
cd ../ansible

# Ansible inventory is auto-generated by Terraform
ansible-playbook playbooks/deploy.yml -i inventory/hosts.ini
```

This deploys:
- Docker on all EC2 instances
- Backend container from ECR
- Frontend container from ECR
- Nginx proxy on bastion host
- Health checks and verification

#### Step 4: Access Your Application

After deployment, get the bastion public IP from Terraform outputs:

```bash
cd terraform
terraform output bastion_public_ip
```

Access the application at: `http://<bastion-public-ip>`

---

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/ci-cd.yml`) automates the entire build, test, and deployment process:

### Pipeline Stages

1. **Lint & Test** (`lint-test`)
   - Backend: ESLint, TypeScript compilation
   - Frontend: ESLint, Next.js build validation

2. **Build** (`build`)
   - Build Docker images for backend, frontend, and proxy
   - Generate image tags using commit SHA
   - Save images as artifacts

3. **Security Scan** (`security-scan`)
   - Trivy vulnerability scanning for all images
   - Fail on HIGH/CRITICAL vulnerabilities

4. **Integration Test** (`integration-test`)
   - Full stack testing with Docker Compose
   - Health checks for all services
   - API endpoint testing

5. **Push to ECR** (`push`)
   - Authenticate with AWS ECR
   - Push images to ECR repositories
   - Tag with commit SHA

6. **Deploy to AWS** (`deploy`)
   - Run Ansible playbook via bastion host
   - Deploy containers to EC2 instances
   - Verify deployment health

### Pipeline Triggers

- **On Push**: Runs on `main` and `develop/**` branches
- **On Pull Request**: Runs on PRs to `main` and `develop/**`
- **Manual**: `workflow_dispatch` for manual triggers

### Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS access key for ECR and deployment |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key |
| `AWS_SESSION_TOKEN` | (Optional) AWS session token for temporary credentials |
| `DB_PASSWORD` | Database password for production |

### Required GitHub Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `AWS_REGION` | AWS region | `eu-west-1` |
| `AWS_ACCOUNT_ID` | AWS account ID for ECR | (required) |

---

## Infrastructure Components

### Terraform Modules

| Module | Purpose | Resources Created |
|--------|---------|-------------------|
| `vpc` | Network infrastructure | VPC, subnets, IGW, NAT Gateway, route tables |
| `compute` | Compute instances | EC2 instances (Bastion, Frontend, Backend) |
| `rds` | Database | RDS PostgreSQL instance |
| `ecr` | Container registry | ECR repositories for Docker images |
| `iam` | Access control | IAM roles, instance profiles, policies |
| `networking` | Security | Security groups, rules |
| `keys` | SSH access | EC2 key pairs |

### Security Groups

- **ALB/Bastion SG**: Allows HTTP (80), HTTPS (443), SSH (22) from Internet
- **Application SG**: Allows ports 3000, 3001, 22 from ALB SG only
- **Database SG**: Allows port 5432 from Application SG only

### IAM Roles

- **EC2 Instance Role**: ECR read access, CloudWatch logs
- **Bastion Role**: SSH access (no ECR needed for public Nginx image)

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Backend health check |
| GET | `/api/notes` | List all notes |
| GET | `/api/notes/:id` | Get note by ID |
| POST | `/api/notes` | Create a new note |
| PUT | `/api/notes/:id` | Update a note |
| DELETE | `/api/notes/:id` | Delete a note |

### Example API Calls

```bash
# Health check
curl http://<bastion-ip>/health

# Get all notes
curl http://<bastion-ip>/api/notes

# Create a note
curl -X POST http://<bastion-ip>/api/notes \
  -H "Content-Type: application/json" \
  -d '{"title":"My Note","content":"Note content","category":"Work"}'
```

---

## Useful Commands

### Local Development

```bash
# View logs
docker compose logs -f

# View logs for specific service
docker compose logs -f backend

# Restart services
docker compose restart

# Stop all services
docker compose down

# Stop and remove volumes (WARNING: deletes data)
docker compose down -v

# Rebuild images
docker compose build --no-cache
```

### Terraform

```bash
# Initialize Terraform
terraform init

# Plan changes
terraform plan

# Apply infrastructure
terraform apply

# Apply only ECR module (for force_delete update)
terraform apply -target=module.ecr

# Destroy infrastructure
terraform destroy

# View outputs
terraform output

# List resources in state
terraform state list
```

### Ansible

```bash
# Validate playbook syntax
ansible-playbook playbooks/deploy.yml --syntax-check -i inventory/hosts.ini

# Dry run (check mode)
ansible-playbook playbooks/deploy.yml --check -i inventory/hosts.ini

# Deploy application
ansible-playbook playbooks/deploy.yml -i inventory/hosts.ini

# Test connectivity
ansible all -i inventory/hosts.ini -m ping
```

### AWS CLI

```bash
# List ECR repositories
aws ecr describe-repositories --region eu-west-1

# List images in repository
aws ecr list-images --repository-name terraform-ansible-webapp-backend --region eu-west-1

# Force delete ECR repository (if needed)
aws ecr delete-repository --repository-name terraform-ansible-webapp-backend --region eu-west-1 --force
```

---

## Troubleshooting

### Terraform Issues

**ECR Repository Not Empty Error**
```bash
# Use the helper script to force-delete ECR repos
.\terraform\scripts\destroy-ecr.ps1

# Or manually:
aws ecr delete-repository --repository-name terraform-ansible-webapp-backend --region eu-west-1 --force
terraform state rm 'module.ecr.aws_ecr_repository.main["backend"]'
terraform destroy
```

**State Lock Issues**
```bash
# If Terraform is stuck, check for lock file
terraform force-unlock <LOCK_ID>
```

### Ansible Issues

**Python Version Compatibility**
- The playbook automatically bootstraps Python 3 on EC2 instances
- Uses `raw` module to install Python before gathering facts

**SSH Connection Issues**
- Verify SSH key is correct: `ssh -i ansible/keys/<key>.pem ec2-user@<bastion-ip>`
- Check security group allows SSH from your IP
- Verify bastion host is running: `terraform output bastion_public_ip`

**Module Not Found Errors**
- Ensure Ansible version >= 8.0: `ansible --version`
- Collections are bundled with Ansible 8.x

### Application Issues

**Container Health Check Failures**
- Check container logs: `docker logs <container-name>` (on EC2)
- Verify environment variables are set correctly
- Check database connectivity from backend container

**Database Connection Issues**
- Verify RDS security group allows connections from application SG
- Check RDS endpoint: `terraform output db_endpoint`
- Test connection: `psql -h <rds-endpoint> -U dbadmin -d notesdb`

### CI/CD Pipeline Issues

**Build Failures**
- Check GitHub Actions logs for specific error
- Verify all required secrets are set in GitHub repository settings
- Ensure Docker build context is correct

**Deployment Failures**
- Verify AWS credentials are correct
- Check Ansible inventory is generated correctly
- Review Ansible playbook logs in GitHub Actions output

---

## Security Considerations

- ✅ **Non-root users** in containers
- ✅ **3-tier security groups** (Public → Application → Database)
- ✅ **Private subnets** for application and database
- ✅ **NAT Gateway** for outbound-only internet access
- ✅ **No hardcoded credentials** (all via environment variables)
- ✅ **Security headers** via Nginx
- ✅ **Vulnerability scanning** in CI/CD (Trivy)
- ✅ **Multi-stage builds** (smaller attack surface)
- ✅ **Encrypted EBS volumes** for EC2 instances
- ✅ **RDS encryption at rest**
- ✅ **IAM roles** with least privilege
- ✅ **ECR image scanning** on push

---

## Cost Optimization

- **Single NAT Gateway** (configurable via `single_nat_gateway` variable)
- **EC2 t2.micro/t3.micro** instances (free tier eligible)
- **RDS db.t3.micro** (free tier eligible)
- **ECR lifecycle policies** to clean up old images
- **VPC Flow Logs** optional (can be disabled)

---

## Future Improvements

- [ ] Add TLS/HTTPS support with ACM certificates
- [ ] Implement Application Load Balancer (ALB) instead of single bastion
- [ ] Add Auto Scaling Groups for EC2 instances
- [ ] Implement blue-green deployments
- [ ] Add Prometheus/Grafana monitoring
- [ ] Implement container logging aggregation (CloudWatch Logs)
- [ ] Add database migrations framework
- [ ] Implement authentication/authorization (JWT, OAuth)
- [ ] Add multi-region deployment
- [ ] Implement infrastructure cost monitoring

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## Authors

- **DevopsGroups** - Infrastructure, deployment automation, and application development

---

## Acknowledgments

- AWS for cloud infrastructure
- HashiCorp for Terraform
- Ansible for configuration management
- Docker for containerization
- NestJS and Next.js communities
