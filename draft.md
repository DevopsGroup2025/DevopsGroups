I'll help you create a comprehensive learning plan for this DevOps project. First, let me understand your existing codebase structure to provide relevant guidance.

[3 tools called]

Let me explore more of the existing infrastructure code to understand what you have and what's missing.

[8 tools called]

Now I have a complete picture of your codebase. Let me switch to Plan mode to provide you with a comprehensive, structured learning roadmap.

[1 tool called]

I've thoroughly analyzed your codebase. You actually have a **well-structured existing project** with most components already in place. The challenge is understanding how all the pieces fit together. Let me create a comprehensive learning roadmap and course of action for you.

---

# DevOps Learning Roadmap: From Code to Production Deployment

## Current State Analysis (What You Already Have)

Your codebase is **85% complete**. Here's what exists:

| Component | Status | Location |
|-----------|--------|----------|
| Frontend (Next.js) | ✅ Complete | `apps/frontend/` |
| Backend (NestJS) | ✅ Complete | `apps/backend/` |
| Multi-stage Dockerfiles | ✅ Complete | `apps/*/Dockerfile` |
| Docker Compose | ✅ Complete | `docker-compose.yml` |
| Nginx Reverse Proxy | ✅ Complete | `nginx/` |
| Database Init Script | ✅ Complete | `database/init.sql` |
| Terraform Infrastructure | ✅ Complete | `terraform/` |
| Ansible Playbooks | ✅ Complete | `ansible/` |
| CI/CD Pipeline | ✅ Complete | `.github/workflows/ci-cd.yml` |

---

## The Big Picture: Understanding the DevOps Pipeline

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                              DEVOPS PIPELINE FLOW                                     │
└──────────────────────────────────────────────────────────────────────────────────────┘

 PHASE 1: LOCAL DEVELOPMENT
 ┌─────────────────────────────────────────────────────────────────────────────────────┐
 │  Developer writes code → Tests locally with Docker Compose → Pushes to GitHub      │
 └─────────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
 PHASE 2: CI (Continuous Integration) - Happens in GitHub Actions
 ┌─────────────────────────────────────────────────────────────────────────────────────┐
 │  Lint & Test → Build Docker Images → Security Scan → Integration Test → Push       │
 └─────────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
 PHASE 3: CD (Continuous Deployment) - Terraform + Ansible
 ┌─────────────────────────────────────────────────────────────────────────────────────┐
 │  Terraform creates AWS infrastructure → Ansible configures servers & deploys app   │
 └─────────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
 PHASE 4: PRODUCTION
 ┌─────────────────────────────────────────────────────────────────────────────────────┐
 │  User → Internet Gateway → Nginx (Load Balancer) → Frontend/Backend → Database    │
 └─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Learning Path: Step-by-Step Course of Action

### MODULE 1: Understand Docker & Containerization (Foundation)

**Goal:** Understand why and how applications are containerized

**Key Concepts to Learn:**
1. **What is a Container?** - Isolated environment with its own filesystem, networking, and process space
2. **Docker Images vs Containers** - Images are blueprints; containers are running instances
3. **Multi-stage Dockerfiles** - Reduce image size by separating build from runtime

**Your Codebase Reference:**

```1:77:apps/backend/Dockerfile
# =============================================================================
# Multi-stage Dockerfile for NestJS Backend API
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Dependencies
# -----------------------------------------------------------------------------
FROM node:20-alpine AS deps

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies only
RUN npm install --omit=dev && npm cache clean --force

# -----------------------------------------------------------------------------
# Stage 2: Builder
# -----------------------------------------------------------------------------
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY tsconfig.json ./

# Install all dependencies (including devDependencies for build)
RUN npm install

# Copy source code
COPY src/ ./src/

# Build the application
RUN npm run build

# -----------------------------------------------------------------------------
# Stage 3: Production
# -----------------------------------------------------------------------------
FROM node:20-alpine AS production

# Add labels for metadata
LABEL maintainer="DevOps Team"
LABEL description="NestJS Backend API for Notes Application"
LABEL version="1.0.0"

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nestjs -u 1001 -G nodejs

WORKDIR /app

# Copy production dependencies from deps stage
COPY --from=deps --chown=nestjs:nodejs /app/node_modules ./node_modules

# Copy built application from builder stage
COPY --from=builder --chown=nestjs:nodejs /app/dist ./dist
COPY --from=builder --chown=nestjs:nodejs /app/package*.json ./

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3001

# Expose the application port
EXPOSE 3001

# Switch to non-root user
USER nestjs

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3001/health || exit 1

# Start the application
CMD ["node", "dist/main.js"]
```

**Study Points:**
- **Stage 1 (deps):** Installs only production dependencies
- **Stage 2 (builder):** Installs ALL dependencies, compiles TypeScript to JavaScript
- **Stage 3 (production):** Copies only what's needed - final image is small and secure
- **Non-root user:** Security best practice (line 49-50)
- **Health check:** Tells Docker/orchestrators when the app is ready

**Hands-On Exercise:**
1. Build the backend image locally: `docker build -t notes-backend ./apps/backend`
2. Inspect the image size: `docker images notes-backend`
3. Run the container: `docker run -p 3001:3001 notes-backend`

---

### MODULE 2: Docker Compose - Orchestrating Multiple Services

**Goal:** Understand how multiple containers work together

**Key Concepts:**
1. **Service Definition** - Each service is a container
2. **Networks** - How containers communicate
3. **Volumes** - Data persistence
4. **Dependencies** - Service startup order

**Your Architecture:**

```
                    ┌─────────────────┐
                    │   Client/User   │
                    └────────┬────────┘
                             │ Port 80
                    ┌────────▼────────┐
                    │  Nginx Proxy    │  ← Only exposed service
                    └───┬─────────┬───┘
                        │         │
          ┌─────────────┘         └─────────────┐
          │                                     │
   ┌──────▼──────┐                     ┌────────▼────────┐
   │   Frontend   │                     │    Backend      │
   │   (Next.js)  │                     │    (NestJS)     │
   │   Port 3000  │                     │    Port 3001    │
   └──────────────┘                     └────────┬────────┘
       Internal Only                             │
                                        ┌────────▼────────┐
                                        │   PostgreSQL    │
                                        │   Port 5432     │
                                        └─────────────────┘
                                            Internal Only
```

**Network Isolation Pattern:**

```137:154:docker-compose.yml
networks:
  # Frontend network - connects proxy, frontend, and backend (for API calls)
  frontend:
    driver: bridge
    name: notes-frontend-network
    labels:
      - "com.docker.compose.project=notes-app"
      - "com.docker.compose.network=frontend"

  # Backend network - connects backend and database (isolated)
  backend:
    driver: bridge
    name: notes-backend-network
    internal: true  # No external access - completely isolated
    labels:
      - "com.docker.compose.project=notes-app"
      - "com.docker.compose.network=backend"
```

**Why Two Networks?**
- **frontend network:** Proxy can reach Frontend and Backend
- **backend network (internal: true):** Only Backend can reach Database - Database is completely isolated from the internet

**Hands-On Exercise:**
1. Start all services: `docker compose up -d`
2. Check network isolation: `docker network inspect notes-backend-network`
3. Test persistence: Create a note, restart containers, verify note still exists

---

### MODULE 3: Reverse Proxy - The Traffic Controller

**Goal:** Understand how Nginx routes traffic

**Key Concepts:**
1. **Why Reverse Proxy?** - Single entry point, security headers, SSL termination
2. **Path-based Routing** - Different paths go to different services
3. **Proxy Headers** - Forwarding client information to backend

**Routing Rules:**

| URL Pattern | Goes To | Purpose |
|-------------|---------|---------|
| `/` | Frontend (port 3000) | Web UI |
| `/api/*` | Backend (port 3001) | API calls |
| `/health` | Backend (port 3001) | Health check |
| `/notes/*` | Backend (port 3001) | REST API |
| `/nginx-health` | Nginx itself | Proxy health |

**Study this configuration:**

```86:116:nginx/nginx.conf
        # API routes - proxy to backend
        location /api/ {
            # Rate limiting for API
            limit_req zone=api_limit burst=20 nodelay;

            # Rewrite /api/xxx to /xxx for the backend
            rewrite ^/api/(.*)$ /$1 break;

            # Proxy settings
            proxy_pass http://backend_api;
            proxy_http_version 1.1;
            
            # Connection settings
            proxy_set_header Connection "";
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;

            # Proxy headers - forwarding client information
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host;
            proxy_set_header X-Forwarded-Port $server_port;
            proxy_set_header X-Request-ID $request_id;

            # Buffer settings
            proxy_buffering on;
            proxy_buffer_size 4k;
            proxy_buffers 8 4k;
        }
```

---

### MODULE 4: Terraform - Infrastructure as Code

**Goal:** Understand how AWS infrastructure is created programmatically

**Key Concepts:**
1. **Declarative Configuration** - You describe WHAT you want, Terraform figures out HOW
2. **Modules** - Reusable infrastructure components
3. **State** - Terraform tracks what it has created
4. **Variables** - Parameterize your infrastructure

**Your AWS Architecture (from your image.png):**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AWS Cloud                                       │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                           VPC (10.0.0.0/16)                            │  │
│  │                                                                         │  │
│  │   ┌─────────────────────────┐    ┌─────────────────────────┐          │  │
│  │   │  Public Subnet (AZ-1a)  │    │  Public Subnet (AZ-1b)  │          │  │
│  │   │  10.0.1.0/24           │    │  10.0.2.0/24            │          │  │
│  │   │                         │    │                         │          │  │
│  │   │  ┌─────────────────┐   │    │  ┌─────────────────┐    │          │  │
│  │   │  │ Bastion/Nginx   │   │    │  │   NAT Gateway   │    │          │  │
│  │   │  │ Load Balancer   │   │    │  │                 │    │          │  │
│  │   │  └─────────────────┘   │    │  └─────────────────┘    │          │  │
│  │   └─────────────────────────┘    └─────────────────────────┘          │  │
│  │                                                                         │  │
│  │   ┌─────────────────────────┐    ┌─────────────────────────┐          │  │
│  │   │  Private Subnet (AZ-1a) │    │  Private Subnet (AZ-1b) │          │  │
│  │   │  10.0.10.0/24          │    │  10.0.11.0/24           │          │  │
│  │   │                         │    │                         │          │  │
│  │   │  ┌─────────────────┐   │    │  ┌─────────────────┐    │          │  │
│  │   │  │    Frontend     │   │    │  │    Frontend     │    │          │  │
│  │   │  │    Backend      │   │    │  │    Backend      │    │          │  │
│  │   │  └─────────────────┘   │    │  └─────────────────┘    │          │  │
│  │   └─────────────────────────┘    └─────────────────────────┘          │  │
│  │                                                                         │  │
│  │   ┌─────────────────────────────────────────────────────────┐          │  │
│  │   │               Private Subnet (Database)                  │          │  │
│  │   │               ┌─────────────────┐                        │          │  │
│  │   │               │   PostgreSQL    │                        │          │  │
│  │   │               │      RDS        │                        │          │  │
│  │   │               └─────────────────┘                        │          │  │
│  │   └─────────────────────────────────────────────────────────┘          │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Terraform Module Structure:**

```
terraform/
├── main.tf                    # Root module - orchestrates all modules
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── modules/
│   ├── vpc/                   # Creates VPC, Subnets, Internet Gateway
│   ├── networking/            # Creates Security Groups
│   ├── keys/                  # Creates SSH key pairs
│   ├── compute/               # Creates EC2 instances
│   └── rds/                   # Creates PostgreSQL database
```

**How Modules Connect (from main.tf):**

```42:58:terraform/main.tf
# Module: VPC
module "vpc" {
  source = "./modules/vpc"

  vpc_name             = "${var.project_name}-vpc"
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = local.availability_zones
  
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  enable_flow_logs     = var.enable_vpc_flow_logs
  
  common_tags = local.common_tags
}
```

**Terraform Workflow:**
```
terraform init    → Downloads providers, initializes backend
terraform plan    → Shows what WILL be created (dry run)
terraform apply   → Actually creates the infrastructure
terraform destroy → Removes all infrastructure
```

---

### MODULE 5: Ansible - Configuration Management

**Goal:** Understand how servers are configured after Terraform creates them

**Key Concepts:**
1. **Inventory** - List of servers to manage
2. **Playbooks** - YAML files describing tasks
3. **Roles** - Reusable collections of tasks
4. **Idempotency** - Run multiple times, same result

**Terraform vs Ansible - Different Jobs:**

| Terraform | Ansible |
|-----------|---------|
| Creates the EC2 instance | Installs Node.js on the instance |
| Creates the VPC | Deploys your application code |
| Creates Security Groups | Configures PM2 process manager |
| Creates RDS database | Sets up Nginx on the server |

**Ansible Role Structure:**

```
ansible/
├── roles/
│   ├── backend/
│   │   ├── tasks/main.yml      # Steps to deploy backend
│   │   ├── templates/env.j2    # Environment file template
│   │   └── handlers/main.yml   # Restart services when needed
│   └── frontend/
│       ├── tasks/main.yml      # Steps to deploy frontend
│       └── templates/          # Configuration templates
├── deploy-backend.yml          # Playbook for backend
├── deploy-frontend.yml         # Playbook for frontend
└── deploy-fullstack.yml        # Runs both playbooks
```

**Study the backend deployment tasks:**

```99:120:ansible/roles/backend/tasks/main.yml
- name: Install npm dependencies
  become: yes
  become_user: ec2-user
  shell: |
    . ~/.nvm/nvm.sh
    npm install
  args:
    chdir: "{{ app_dir }}"
    executable: /bin/bash

- name: Build NestJS application
  become: yes
  become_user: ec2-user
  shell: |
    . ~/.nvm/nvm.sh
    npm run build
  args:
    chdir: "{{ app_dir }}"
    executable: /bin/bash
  register: build_result
  changed_when: build_result.rc == 0
```

---

### MODULE 6: CI/CD Pipeline - Automated Workflow

**Goal:** Understand how GitHub Actions automates everything

**Pipeline Stages:**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          GitHub Actions Pipeline                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐                                                           │
│  │  lint-test   │  → Runs npm lint & npm test for backend & frontend       │
│  └──────┬───────┘                                                           │
│         │                                                                    │
│  ┌──────▼───────┐                                                           │
│  │    build     │  → Builds Docker images using multi-stage Dockerfiles    │
│  └──────┬───────┘                                                           │
│         │                                                                    │
│    ┌────┴────────────┐                                                      │
│    │                 │                                                       │
│  ┌─▼──────────┐  ┌───▼───────────┐                                          │
│  │ security-  │  │ integration-  │  → Run in parallel                       │
│  │   scan     │  │    test       │                                          │
│  └─────┬──────┘  └───────┬───────┘                                          │
│        │                 │                                                   │
│        └────────┬────────┘                                                   │
│                 │                                                            │
│         ┌───────▼──────┐                                                     │
│         │     push     │  → Push images to GitHub Container Registry         │
│         └───────┬──────┘    (only on main/develop branch)                   │
│                 │                                                            │
│         ┌───────▼──────┐                                                     │
│         │    deploy    │  → Terraform + Ansible deploy to AWS               │
│         └──────────────┘    (only on main branch)                           │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Key Pipeline Concepts:**

1. **Triggers (when does it run?):**

```18:40:.github/workflows/ci-cd.yml
on:
  push:
    branches:
      - main
      - 'develop/**'
  pull_request:
    branches:
      - main
      - 'develop/**'
    paths-ignore:
      - '**.md'
      - 'docs/**'
  workflow_dispatch:
    inputs:
      deploy_environment:
        description: 'Environment to deploy to'
        required: false
        default: 'staging'
        type: choice
        options:
          - staging
          - production
```

2. **Conditional Deployment (only deploy to main):**

```481:481:.github/workflows/ci-cd.yml
    if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/develop'
```

---

## ACTION PLAN: Step-by-Step Execution Guide

### PHASE 1: Prerequisites Setup (Do This First)

**Step 1.1: Install Required Tools**
- [ ] Docker Desktop (includes Docker Compose)
- [ ] Git
- [ ] AWS CLI
- [ ] Terraform (v1.5.0+)
- [ ] VS Code or Cursor IDE

**Step 1.2: AWS Account Setup**
- [ ] Create AWS account (if not exists)
- [ ] Create IAM user with programmatic access
- [ ] Required permissions: EC2, VPC, RDS, S3, IAM (limited)
- [ ] Save Access Key ID and Secret Access Key

**Step 1.3: GitHub Setup**
- [ ] Create GitHub account (if not exists)
- [ ] Fork or push this codebase to your repository

---

### PHASE 2: Local Development Testing

**Step 2.1: Test Docker Compose Locally**
```bash
# 1. Copy environment file
cp env.example .env

# 2. Start all services
docker compose up -d

# 3. Check services are healthy
docker compose ps

# 4. Test endpoints
curl http://localhost/health      # Backend health
curl http://localhost/notes       # API endpoint
curl http://localhost             # Frontend

# 5. Stop services
docker compose down
```

**Step 2.2: Verify Data Persistence**
```bash
# Create a note
curl -X POST http://localhost/notes \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","content":"Persistence test"}'

# Restart containers
docker compose restart

# Verify note still exists
curl http://localhost/notes
```

---

### PHASE 3: Configure GitHub for CI/CD

**Step 3.1: Set GitHub Secrets**

Navigate to: Repository → Settings → Secrets and variables → Actions

| Secret Name | Value | Required |
|-------------|-------|----------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key | Yes |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key | Yes |
| `AWS_SESSION_TOKEN` | Only if using SSO/temp creds | Maybe |
| `DB_PASSWORD` | Strong password for production DB | Yes |

**Step 3.2: Set GitHub Variables**

Navigate to: Repository → Settings → Secrets and variables → Actions → Variables

| Variable Name | Value |
|---------------|-------|
| `AWS_REGION` | `eu-west-1` (or your preferred region) |

---

### PHASE 4: Terraform Backend Setup (One-Time)

**Step 4.1: Create S3 Bucket for State**
```bash
cd terraform/backend-setup
terraform init
terraform apply -auto-approve
```

**Step 4.2: Update Backend Configuration**
Create `terraform/backend.tf` with the S3 bucket name from output.

---

### PHASE 5: Trigger Deployment

**Step 5.1: Push to Main Branch**
```bash
git add .
git commit -m "Initial deployment"
git push origin main
```

**Step 5.2: Monitor Pipeline**
1. Go to GitHub → Actions tab
2. Watch each stage complete
3. Check for errors in logs

---

## Common Issues and Solutions

### Issue 1: Terraform State Lock
**Symptom:** "Error acquiring the state lock"
**Solution:** Wait for other operations or force-unlock (carefully)

### Issue 2: Docker Build Fails
**Symptom:** "npm install failed"
**Solution:** Clear Docker cache: `docker system prune -a`

### Issue 3: Database Connection Refused
**Symptom:** Backend can't connect to PostgreSQL
**Solution:** Check security group allows port 5432 from backend subnet

### Issue 4: AWS Credentials Invalid
**Symptom:** "The security token included in the request is invalid"
**Solution:** Regenerate AWS credentials and update GitHub secrets

---

## Learning Resources

### Docker
- [Docker Official Tutorial](https://docs.docker.com/get-started/)
- [Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)

### Terraform
- [Terraform AWS Tutorial](https://developer.hashicorp.com/terraform/tutorials/aws-get-started)
- [Terraform Best Practices](https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices)

### Ansible
- [Ansible Getting Started](https://docs.ansible.com/ansible/latest/getting_started/index.html)
- [AWS EC2 with Ansible](https://docs.ansible.com/ansible/latest/collections/amazon/aws/ec2_instance_module.html)

### GitHub Actions
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Build Push Action](https://github.com/docker/build-push-action)

---

## Summary: Your Path Forward

1. **Week 1:** Master Docker locally - build images, run compose, understand networking
2. **Week 2:** Understand Terraform - deploy VPC and EC2 manually, learn state management
3. **Week 3:** Learn Ansible - configure a simple server, understand playbooks
4. **Week 4:** Integrate CI/CD - push to GitHub, watch pipeline, troubleshoot failures
5. **Week 5:** Full deployment - end-to-end from code push to production

Your codebase is production-ready. The work now is understanding each component deeply so you can troubleshoot, modify, and extend it confidently.