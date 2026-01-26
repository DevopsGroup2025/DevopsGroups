# AI Video Prompt: AWS Multi-Tier Architecture Animation

## Video Generation Prompt

Create a professional, clean, and industry-standard animated architectural diagram for a multi-tier AWS infrastructure. The style should mimic draw.io/Lucidchart professional diagrams with smooth animations showing the flow of traffic and deployment.

---

## SCENE 1: Title Card (0:00 - 0:05)

**Visual:**
- Clean white background
- Fade in title: "Multi-Tier AWS Infrastructure"
- Subtitle: "Containerized Web Application with Reverse Proxy"
- AWS logo in corner
- Project name: "terraform-ansible-webapp"

---

## SCENE 2: AWS Cloud Region Container (0:05 - 0:15)

**Visual:**
- Animate drawing of large rounded rectangle representing AWS Cloud
- Label: "AWS Cloud - eu-west-1 (Ireland)"
- Inside, draw VPC container with dashed border
- Label: "VPC - 10.0.0.0/16"
- Show 2 Availability Zones (AZ-a and AZ-b) as vertical columns

**Animation:**
- Draw VPC boundary with smooth line animation
- Fade in AZ labels

---

## SCENE 3: Network Layer - Subnets (0:15 - 0:35)

**Visual Components to Draw:**

### Public Subnets (Green/Light Green):
```
┌─────────────────────────────────────────────────────────────┐
│  Public Subnet - AZ-a          │  Public Subnet - AZ-b       │
│  10.0.1.0/24                   │  10.0.2.0/24                │
│  ┌─────────────┐               │                             │
│  │   Bastion   │               │                             │
│  │   Host      │               │                             │
│  │  (Nginx)    │               │                             │
│  └─────────────┘               │                             │
│                                │                             │
│  ┌─────────────┐               │                             │
│  │ NAT Gateway │               │                             │
│  └─────────────┘               │                             │
└─────────────────────────────────────────────────────────────┘
```

### Private Subnets (Blue/Light Blue):
```
┌─────────────────────────────────────────────────────────────┐
│  Private Subnet - AZ-a         │  Private Subnet - AZ-b      │
│  10.0.10.0/24                  │  10.0.11.0/24               │
│  ┌─────────────┐               │  ┌─────────────┐            │
│  │  Frontend   │               │  │   Backend   │            │
│  │  (Next.js)  │               │  │  (NestJS)   │            │
│  │  Port 3000  │               │  │  Port 3001  │            │
│  └─────────────┘               │  └─────────────┘            │
│                                │                             │
│                    ┌───────────────────────┐                 │
│                    │  RDS PostgreSQL       │                 │
│                    │  (Multi-AZ)           │                 │
│                    │  Port 5432            │                 │
│                    └───────────────────────┘                 │
└─────────────────────────────────────────────────────────────┘
```

**Animation:**
- Draw public subnets first (top layer) with green shading
- Animate private subnets appearing below (blue shading)
- Icons appear inside each subnet with subtle bounce effect

---

## SCENE 4: Core Infrastructure Components (0:35 - 1:00)

**Components to Animate (use AWS official icons):**

| Component | Icon | Location | Label |
|-----------|------|----------|-------|
| Internet Gateway | AWS IGW icon | Top of VPC | "Internet Gateway" |
| NAT Gateway | AWS NAT icon | Public Subnet AZ-a | "NAT Gateway" |
| Bastion Host | EC2 icon with Nginx logo | Public Subnet AZ-a | "Bastion/Nginx Proxy (t2.micro)" |
| Frontend | EC2 icon with Next.js logo | Private Subnet AZ-a | "Frontend (Next.js) - Port 3000" |
| Backend | EC2 icon with NestJS logo | Private Subnet AZ-b | "Backend (NestJS) - Port 3001" |
| RDS | RDS PostgreSQL icon | Spanning private subnets | "RDS PostgreSQL - Port 5432" |
| ECR | ECR icon | Outside VPC | "ECR Registry (3 repos)" |

**Animation:**
- Each component draws in with a professional icon appearance
- Labels fade in next to each component
- Slight glow effect on each component as it appears

---

## SCENE 5: Route Tables & Network Flow (1:00 - 1:25)

**Visual:**
- Show Route Table icons connected to subnets
- Public Route Table → Internet Gateway (0.0.0.0/0)
- Private Route Table → NAT Gateway (0.0.0.0/0)

**Diagram:**
```
┌────────────────────┐
│  Public Route      │──────────▶ Internet Gateway ──▶ Internet
│  Table             │
└────────────────────┘
         │
         ▼
   Public Subnets

┌────────────────────┐
│  Private Route     │──────────▶ NAT Gateway ──▶ Internet
│  Table             │            (Outbound Only)
└────────────────────┘
         │
         ▼
   Private Subnets
```

**Animation:**
- Animated dotted lines showing route paths
- Arrows flowing from route tables to gateways
- Labels: "Public RT" and "Private RT"

---

## SCENE 6: Security Groups (1:25 - 1:50)

**Visual - Shield icons around components:**

```
┌─────────────────────────────────────────────────────────────────┐
│  Security Group: ALB/Bastion (Public Tier)                      │
│  ├── Inbound: HTTP (80), HTTPS (443), SSH (22) from 0.0.0.0/0  │
│  └── Outbound: All traffic                                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Security Group: Application (Private Tier)                     │
│  ├── Inbound: Port 3000, 3001, 22 from ALB SG only             │
│  └── Outbound: All traffic (via NAT)                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Security Group: Database (Data Tier)                           │
│  ├── Inbound: Port 5432 from Application SG only               │
│  └── Outbound: All traffic                                      │
└─────────────────────────────────────────────────────────────────┘
```

**Animation:**
- Shield icons appear around each tier
- Animated lock icons showing security
- Arrows showing allowed traffic flow between groups

---

## SCENE 7: Traffic Flow Animation (1:50 - 2:30)

**Animate User Request Flow:**

```
User Request Flow:
══════════════════

  👤 User
    │
    │ HTTP Request (Port 80)
    ▼
┌─────────────┐
│  Internet   │
│  Gateway    │
└─────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│  Bastion Host (Nginx Proxy)         │
│  ├── /              → Frontend:3000 │
│  ├── /api/*         → Backend:3001  │
│  ├── /health        → Backend:3001  │
│  └── /nginx-health  → 200 OK        │
└─────────────────────────────────────┘
    │                    │
    ▼                    ▼
┌───────────┐      ┌───────────┐
│ Frontend  │      │  Backend  │
│ (Next.js) │      │ (NestJS)  │
│ Port 3000 │      │ Port 3001 │
└───────────┘      └───────────┘
                         │
                         ▼
                  ┌───────────┐
                  │    RDS    │
                  │PostgreSQL │
                  │Port 5432  │
                  └───────────┘
```

**Animation:**
- Animated packet/data flowing from user through each component
- Color-coded paths (green for frontend, blue for API)
- Pulse effects showing data transfer
- Response flowing back to user

---

## SCENE 8: CI/CD Pipeline Integration (2:30 - 3:00)

**Visual - GitHub Actions to AWS:**

```
┌─────────────────────────────────────────────────────────────────┐
│                    CI/CD Pipeline                                │
│                                                                  │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐  │
│  │  GitHub  │───▶│  Build   │───▶│   ECR    │───▶│  Deploy  │  │
│  │   Push   │    │  & Test  │    │   Push   │    │ (Ansible)│  │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘  │
│                                                        │        │
└────────────────────────────────────────────────────────│────────┘
                                                         │
                                                         ▼
                                                ┌──────────────┐
                                                │   Bastion    │
                                                │  (SSH Jump)  │
                                                └──────────────┘
                                                    │     │
                                          ┌─────────┘     └─────────┐
                                          ▼                         ▼
                                    ┌──────────┐              ┌──────────┐
                                    │ Frontend │              │ Backend  │
                                    └──────────┘              └──────────┘
```

**Animation:**
- Code commit icon triggering pipeline
- Progress through build stages
- Docker images pushing to ECR
- Ansible deploying through bastion to instances

---

## SCENE 9: Complete Architecture Overview (3:00 - 3:20)

**Full Diagram - All Components Together:**

```
                              ┌─────────────────────────────────────────────────────────────────────────┐
                              │                        AWS Cloud (eu-west-1)                            │
                              │  ┌───────────────────────────────────────────────────────────────────┐  │
                              │  │                      VPC: 10.0.0.0/16                             │  │
                              │  │                                                                   │  │
     ┌──────────┐             │  │  ┌──────────────────────────────────────────────────────────┐    │  │
     │ Internet │             │  │  │              PUBLIC SUBNETS                               │    │  │
     │          │─────────────│──│──│  ┌─────────────┐                      ┌─────────────┐     │    │  │
     └──────────┘             │  │  │  │   Internet  │                      │    NAT      │     │    │  │
           │                  │  │  │  │   Gateway   │                      │   Gateway   │     │    │  │
           │                  │  │  │  └──────┬──────┘                      └──────┬──────┘     │    │  │
           │                  │  │  │         │                                    │            │    │  │
           │                  │  │  │         │         ┌─────────────────┐        │            │    │  │
           │                  │  │  │         └────────▶│    Bastion      │◀───────┘            │    │  │
           │                  │  │  │                   │   (Nginx)       │                     │    │  │
           │                  │  │  │                   │  34.240.x.x     │                     │    │  │
           │                  │  │  │                   └────────┬────────┘                     │    │  │
           │                  │  │  └────────────────────────────│────────────────────────────┘    │  │
           │                  │  │                               │                                  │  │
           │                  │  │  ┌────────────────────────────│────────────────────────────┐    │  │
           │                  │  │  │              PRIVATE SUBNETS                             │    │  │
           │                  │  │  │                            │                             │    │  │
           │                  │  │  │              ┌─────────────┴─────────────┐               │    │  │
           │                  │  │  │              │                           │               │    │  │
           │                  │  │  │      ┌───────▼───────┐           ┌───────▼───────┐       │    │  │
           │                  │  │  │      │   Frontend    │           │   Backend     │       │    │  │
           │                  │  │  │      │   (Next.js)   │           │   (NestJS)    │       │    │  │
           │                  │  │  │      │  10.0.10.x    │           │  10.0.11.x    │       │    │  │
           │                  │  │  │      │   Port 3000   │           │   Port 3001   │       │    │  │
           │                  │  │  │      └───────────────┘           └───────┬───────┘       │    │  │
           │                  │  │  │                                          │               │    │  │
           │                  │  │  │                                  ┌───────▼───────┐       │    │  │
           │                  │  │  │                                  │     RDS       │       │    │  │
           │                  │  │  │                                  │  PostgreSQL   │       │    │  │
           │                  │  │  │                                  │  Port 5432    │       │    │  │
           │                  │  │  │                                  └───────────────┘       │    │  │
           │                  │  │  └──────────────────────────────────────────────────────────┘    │  │
           │                  │  │                                                                   │  │
           │                  │  └───────────────────────────────────────────────────────────────────┘  │
           │                  │                                                                          │
           │                  │  ┌───────────────────┐                                                  │
           │                  │  │       ECR         │  ← Docker Images                                 │
           │                  │  │  - backend repo   │                                                  │
           │                  │  │  - frontend repo  │                                                  │
           │                  │  │  - proxy repo     │                                                  │
           │                  │  └───────────────────┘                                                  │
           │                  └──────────────────────────────────────────────────────────────────────────┘
           │
┌──────────┴──────────┐
│   GitHub Actions    │
│   CI/CD Pipeline    │
└─────────────────────┘
```

**Animation:**
- Full architecture revealed with all connections highlighted
- Data flow animations running continuously
- Subtle pulsing on active connections

---

## SCENE 10: Technology Stack Summary (3:20 - 3:30)

**Visual:**
- Clean sidebar showing technology stack:

```
╔════════════════════════════════════════════╗
║          Technology Stack                   ║
╠════════════════════════════════════════════╣
║  Infrastructure:                            ║
║  ├── Terraform (IaC)                       ║
║  ├── Ansible (Configuration Management)   ║
║  └── GitHub Actions (CI/CD)                ║
║                                            ║
║  Compute:                                  ║
║  ├── EC2 (Amazon Linux 2)                  ║
║  └── Docker Containers                     ║
║                                            ║
║  Application:                              ║
║  ├── Next.js (Frontend)                    ║
║  ├── NestJS (Backend)                      ║
║  └── Nginx (Reverse Proxy)                 ║
║                                            ║
║  Database:                                 ║
║  └── RDS PostgreSQL                        ║
║                                            ║
║  Container Registry:                       ║
║  └── AWS ECR                               ║
╚════════════════════════════════════════════╝
```

---

## STYLE GUIDELINES

### Colors:
- **VPC Border**: #232F3E (AWS dark blue)
- **Public Subnets**: #7AA116 (AWS green) with light fill
- **Private Subnets**: #1A73E8 (Blue) with light fill
- **Security Groups**: #FF9900 (AWS orange) - shields
- **Database**: #3B48CC (Purple/Blue)
- **Connections**: #666666 (Gray) for static, #00A4EF for animated flow
- **Background**: #FFFFFF (White)

### Icons:
- Use official AWS Architecture Icons (2024 version)
- Technology logos (Docker, Next.js, NestJS, PostgreSQL, Nginx)
- Clean, minimalist style

### Text:
- Font: Inter, Roboto, or similar clean sans-serif
- Labels: 12-14pt
- Titles: 18-24pt bold
- All text should be crisp and readable

### Animation Style:
- Smooth easing (ease-in-out)
- Professional transitions (no bouncy/playful animations)
- Flow animations should be subtle and continuous
- Draw effects for lines connecting components
- Fade transitions for labels

---

## EXPORT SPECIFICATIONS

- **Resolution**: 1920x1080 (Full HD) or 4K
- **Frame Rate**: 30fps or 60fps
- **Duration**: 3-4 minutes
- **Format**: MP4 (H.264) or WebM
- **Audio**: Optional subtle background music (professional/corporate)

---

## ADDITIONAL NOTES FOR AI

1. **Keep it Professional**: This is for DevOps/Cloud Engineering context - avoid playful or cartoon-like elements
2. **draw.io Aesthetic**: Aim for the clean, professional look of draw.io/Lucidchart diagrams
3. **AWS Standards**: Follow AWS architecture diagramming best practices
4. **Clear Labels**: Every component must be clearly labeled with its function
5. **Flow Direction**: Always show flow from left-to-right or top-to-bottom
6. **Security Emphasis**: Highlight the 3-tier security architecture (Public → Private → Database)

---

## KEYWORDS FOR AI TOOLS

`AWS architecture diagram animation, professional cloud infrastructure visualization, draw.io style, multi-tier architecture, VPC network diagram, EC2 instances, RDS database, NAT gateway, internet gateway, security groups, route tables, CI/CD pipeline, Docker containers, Terraform infrastructure, clean technical animation, DevOps architecture`


