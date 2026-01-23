# Containerized Multi-Service Web Application with Reverse Proxy and Persistent Database

## Project Overview

This project demonstrates the design and deployment of a **containerized multi-service web application** using **Docker** and **Docker Compose**. The system follows production-style infrastructure practices and focuses on **service orchestration, networking, security, and persistence**, rather than application feature complexity.

The application stack consists of:
- A backend API service (NestJS)
- A frontend application (Next.js)
- A relational database with persistent storage (PostgreSQL)
- A reverse proxy for routing and traffic management (Nginx)
- Isolated container networks and environment-based configuration

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CLIENT (Browser)                                │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ HTTP :80
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         REVERSE PROXY (Nginx)                                │
│                                                                              │
│  • Routes traffic based on URL path                                          │
│  • Adds X-Forwarded-For, X-Real-IP headers                                   │
│  • Rate limiting & security headers                                          │
│  • Health check: /nginx-health                                               │
│  • Port 80 exposed to host                                                   │
└─────────────────────────────────────────────────────────────────────────────┘
                    │                                    │
                    │ /api/*, /health, /notes           │ / (all other routes)
                    ▼                                    ▼
┌───────────────────────────────┐      ┌───────────────────────────────────────┐
│      BACKEND API (NestJS)     │      │         FRONTEND (Next.js)            │
│                               │      │                                       │
│  • REST API endpoints         │      │  • Server-side rendered React         │
│  • Port 3001 (internal only)  │      │  • Port 3000 (internal only)          │
│  • Non-root user: nestjs      │      │  • Non-root user: nextjs              │
│  • Health check: /health      │      │  • Standalone output mode             │
│  • Multi-stage Dockerfile     │      │  • Multi-stage Dockerfile             │
└───────────────────────────────┘      └───────────────────────────────────────┘
                    │
                    │ PostgreSQL :5432
                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         DATABASE (PostgreSQL)                                │
│                                                                              │
│  • Persistent volume: postgres_data                                          │
│  • Init script for schema creation                                           │
│  • Internal network only (no host access)                                    │
│  • Only accepts connections from backend                                     │
└─────────────────────────────────────────────────────────────────────────────┘

                              NETWORK TOPOLOGY
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                    FRONTEND NETWORK (bridge)                         │    │
│  │                                                                      │    │
│  │    ┌─────────┐      ┌──────────┐      ┌──────────┐                  │    │
│  │    │  Proxy  │◄────►│ Frontend │      │ Backend  │                  │    │
│  │    └─────────┘      └──────────┘      └──────────┘                  │    │
│  │                                              │                       │    │
│  └──────────────────────────────────────────────┼───────────────────────┘    │
│                                                 │                             │
│  ┌──────────────────────────────────────────────┼───────────────────────┐    │
│  │                    BACKEND NETWORK (internal)│                       │    │
│  │                                              ▼                       │    │
│  │                      ┌──────────┐      ┌──────────┐                  │    │
│  │                      │ Backend  │◄────►│ Database │                  │    │
│  │                      └──────────┘      └──────────┘                  │    │
│  │                                                                      │    │
│  └──────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Service Communication

| From | To | Protocol | Network | Port |
|------|----|----------|---------|------|
| Client | Proxy | HTTP | Host | 80 |
| Proxy | Frontend | HTTP | frontend | 3000 |
| Proxy | Backend | HTTP | frontend | 3001 |
| Backend | Database | PostgreSQL | backend | 5432 |

### Key Points:
- **Database Isolation**: The database is on an internal network (`backend`) with no external access
- **No Direct Port Exposure**: Frontend and Backend services don't expose ports to the host
- **All Traffic Through Proxy**: External clients can only access services through the Nginx reverse proxy
- **Health Checks**: All services have health checks for proper dependency management

---

## Project Structure

```
DevopsGroups/
├── .github/
│   └── workflows/
│       └── ci-cd.yml           # GitHub Actions CI/CD pipeline
├── apps/
│   ├── backend/
│   │   ├── src/                # NestJS source code
│   │   ├── Dockerfile          # Multi-stage Dockerfile
│   │   ├── .dockerignore       # Docker build exclusions
│   │   ├── package.json        # Dependencies
│   │   └── tsconfig.json       # TypeScript config
│   └── frontend/
│       ├── src/                # Next.js source code
│       ├── Dockerfile          # Multi-stage Dockerfile
│       ├── .dockerignore       # Docker build exclusions
│       ├── package.json        # Dependencies
│       └── next.config.js      # Next.js config (standalone output)
├── nginx/
│   ├── nginx.conf              # Nginx reverse proxy configuration
│   └── Dockerfile              # Nginx Dockerfile
├── database/
│   └── init.sql                # PostgreSQL initialization script
├── ansible/                    # Ansible deployment playbooks
├── terraform/                  # Terraform infrastructure code
├── docker-compose.yml          # Docker Compose orchestration
├── env.example                 # Environment variables template
└── README.md                   # This file
```

---

## How to Run the Project

### Prerequisites

- Docker 24.0+ and Docker Compose v2
- Git

### Quick Start

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

4. **Verify services are running**
   ```bash
   docker compose ps
   ```

5. **Access the application**
   - Frontend: http://localhost
   - Backend API: http://localhost/api or http://localhost/notes
   - Health Check: http://localhost/health

### Useful Commands

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

# Scale services (if needed)
docker compose up -d --scale backend=2
```

---

## Key DevOps Decisions

### 1. Multi-Stage Dockerfiles
- **Rationale**: Reduces final image size by separating build dependencies from runtime
- **Implementation**: 
  - Stage 1: Install dependencies
  - Stage 2: Build application
  - Stage 3: Production runtime with minimal footprint

### 2. Non-Root Users
- **Rationale**: Security best practice to limit container privileges
- **Implementation**: Created `nestjs` and `nextjs` users with UID 1001

### 3. Network Isolation
- **Rationale**: Defense in depth - database should never be directly accessible
- **Implementation**: 
  - `frontend` network: Connects proxy, frontend, and backend
  - `backend` network: Internal-only, connects backend to database

### 4. Health Checks
- **Rationale**: Enables proper service dependency management and auto-recovery
- **Implementation**: All services have health checks with appropriate intervals

### 5. Named Volumes
- **Rationale**: Data persistence across container restarts
- **Implementation**: `postgres_data` volume for database

### 6. Environment-Based Configuration
- **Rationale**: Separation of configuration from code
- **Implementation**: All sensitive values via environment variables

### 7. Reverse Proxy Pattern
- **Rationale**: Single entry point, TLS termination point, security headers
- **Implementation**: Nginx with path-based routing and proxy headers

### 8. CI/CD Pipeline
- **Rationale**: Automated testing, building, and deployment
- **Implementation**: GitHub Actions with multiple stages:
  - Lint & Test
  - Build Docker images
  - Security scanning (Trivy)
  - Integration testing
  - Push to registry
  - Deploy to AWS

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Backend health check |
| GET | `/notes` | List all notes |
| GET | `/notes/:id` | Get note by ID |
| POST | `/notes` | Create a new note |
| PUT | `/notes/:id` | Update a note |
| DELETE | `/notes/:id` | Delete a note |

### Example API Calls

```bash
# Health check
curl http://localhost/health

# Get all notes
curl http://localhost/notes

# Create a note
curl -X POST http://localhost/notes \
  -H "Content-Type: application/json" \
  -d '{"title":"My Note","content":"Note content","category":"Work"}'

# Update a note
curl -X PUT http://localhost/notes/1 \
  -H "Content-Type: application/json" \
  -d '{"title":"Updated Title"}'

# Delete a note
curl -X DELETE http://localhost/notes/1
```

---

## Testing Data Persistence

```bash
# Create a note
curl -X POST http://localhost/notes \
  -H "Content-Type: application/json" \
  -d '{"title":"Persistence Test","content":"Testing data persistence"}'

# Restart containers (not volumes)
docker compose restart

# Verify note still exists
curl http://localhost/notes
```

---

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/ci-cd.yml`) includes:

1. **Lint & Test**: Code quality checks for backend and frontend
2. **Build**: Multi-stage Docker image builds with caching
3. **Security Scan**: Trivy vulnerability scanning
4. **Integration Test**: Full stack testing with Docker Compose
5. **Push**: Push images to GitHub Container Registry (on main/develop)
6. **Deploy**: Deploy to AWS using Terraform and Ansible (on main)

### Required Secrets

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS access key for deployment |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key for deployment |
| `DB_PASSWORD` | Database password for production |
| `DB_ENDPOINT` | RDS endpoint for production |

---

## Troubleshooting

### Services not starting
```bash
# Check logs
docker compose logs

# Check specific service
docker compose logs backend

# Check health status
docker compose ps
```

### Database connection issues
```bash
# Check if database is healthy
docker compose exec database pg_isready -U dbadmin -d notesdb

# Connect to database
docker compose exec database psql -U dbadmin -d notesdb
```

### Proxy not routing correctly
```bash
# Check nginx logs
docker compose logs proxy

# Test nginx config
docker compose exec proxy nginx -t
```

---

## Security Considerations

- ✅ Non-root users in containers
- ✅ Database isolated on internal network
- ✅ No hardcoded credentials
- ✅ Security headers via Nginx
- ✅ Rate limiting on API endpoints
- ✅ Vulnerability scanning in CI/CD
- ✅ Multi-stage builds (smaller attack surface)

---

## Future Improvements

- [ ] Add TLS/HTTPS support
- [ ] Implement container logging aggregation
- [ ] Add Prometheus metrics
- [ ] Implement blue-green deployments
- [ ] Add database migrations
- [ ] Implement authentication/authorization
