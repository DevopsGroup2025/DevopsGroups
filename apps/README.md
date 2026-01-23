# Application Documentation

## Overview

This directory contains standalone applications that are deployed by Ansible to AWS infrastructure. Applications are completely independent of infrastructure code and can be developed, tested, and version-controlled separately.

## Architecture Principle

**Separation of Concerns:**
- `apps/` - Application code (this directory)
- `terraform/` - Infrastructure provisioning
- `ansible/` - Deployment automation

Applications are not embedded as Ansible templates. Ansible copies these standalone apps and injects environment-specific configuration during deployment.

## Applications

### Backend (NestJS API)

**Location:** `backend/`

**Technology Stack:**
- NestJS 10.x
- TypeScript
- TypeORM
- PostgreSQL driver
- Class validator

**Structure:**
```
backend/
├── src/
│   ├── main.ts                 # Application entry point
│   ├── app.module.ts           # Root module with TypeORM config
│   ├── app.controller.ts       # Health check endpoint
│   ├── app.service.ts          # Base service
│   └── notes/                  # Notes feature module
│       ├── note.entity.ts      # Note entity (TypeORM)
│       ├── notes.controller.ts # REST API endpoints
│       ├── notes.service.ts    # Business logic
│       ├── notes.module.ts     # Module definition
│       └── note.dto.ts         # Data transfer objects
├── package.json                # Dependencies
├── tsconfig.json               # TypeScript config
└── .env.example                # Environment template
```

**API Endpoints:**
- `GET /health` - Health check
- `GET /notes` - List all notes (with search/filter)
- `GET /notes/:id` - Get note by ID
- `POST /notes` - Create note
- `PUT /notes/:id` - Update note
- `DELETE /notes/:id` - Delete note

**Environment Variables:**
```env
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=dbadmin
DB_PASSWORD=password
DB_NAME=notesdb
NODE_ENV=production
PORT=3001
```

**Features:**
- Full CRUD operations on notes
- Search by title/content
- Filter by category
- Pin/unpin notes
- PostgreSQL with TypeORM
- Input validation
- Error handling
- CORS enabled

### Frontend (Next.js)

**Location:** `frontend/`

**Technology Stack:**
- Next.js 14
- React 18
- TypeScript
- Server Components
- App Router

**Structure:**
```
frontend/
├── app/
│   ├── layout.tsx              # Root layout
│   ├── page.tsx                # Main notes page
│   ├── styles.css              # Global styles
│   └── components/
│       ├── NotesList.tsx       # Notes display grid
│       ├── NoteForm.tsx        # Create/edit form
│       └── SearchBar.tsx       # Search and filter
├── package.json                # Dependencies
├── tsconfig.json               # TypeScript config
├── next.config.js              # Next.js config
└── .env.local.example          # Environment template
```

**Features:**
- Responsive grid layout
- Create, edit, delete notes
- Pin important notes to top
- Search by title/content
- Filter by category (Work, Personal, Ideas)
- Real-time UI updates
- Clean, modern design
- Error handling

**Environment Variables:**
```env
NEXT_PUBLIC_API_URL=http://backend-server:3001
```

## Development Setup

### Local Development Prerequisites

- Node.js 20.x or higher
- PostgreSQL 15.x
- npm or yarn

### Backend Development

```bash
cd apps/backend

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your local database credentials

# Run database migrations (if any)
npm run migration:run

# Start development server
npm run start:dev

# API available at http://localhost:3001
```

**Development commands:**
```bash
npm run start:dev    # Hot reload development
npm run build        # Production build
npm run start:prod   # Run production build
npm run test         # Run tests
npm run lint         # Lint code
```

### Frontend Development

```bash
cd apps/frontend

# Install dependencies
npm install

# Configure environment
cp .env.local.example .env.local
# Edit .env.local with backend URL (http://localhost:3001)

# Start development server
npm run dev

# App available at http://localhost:3000
```

**Development commands:**
```bash
npm run dev          # Hot reload development
npm run build        # Production build
npm run start        # Run production build
npm run lint         # Lint code
```

### Full Stack Local Testing

1. **Start PostgreSQL:**
   ```bash
   # Using Docker
   docker run --name postgres-notes \
     -e POSTGRES_DB=notesdb \
     -e POSTGRES_USER=dbadmin \
     -e POSTGRES_PASSWORD=password \
     -p 5432:5432 -d postgres:15
   ```

2. **Start Backend:**
   ```bash
   cd apps/backend
   npm run start:dev
   ```

3. **Start Frontend:**
   ```bash
   cd apps/frontend
   npm run dev
   ```

4. **Access:** http://localhost:3000

## Production Deployment

These applications are deployed by Ansible to AWS infrastructure:

1. **Terraform** provisions infrastructure (EC2, RDS, VPC)
2. **Ansible** copies applications and configures environment
3. **PM2** manages processes on servers

**Deployment process:**
- Applications copied via `synchronize` module
- Environment files generated from templates
- Dependencies installed with `npm install`
- Built with `npm run build`
- Started with PM2 process manager

See [../ANSIBLE.md](../ANSIBLE.md) for deployment details.

## Application Features

### Notes CRUD Operations

**Create Note:**
```bash
curl -X POST http://backend:3001/notes \
  -H "Content-Type: application/json" \
  -d '{
    "title": "My Note",
    "content": "Note content here",
    "category": "Work",
    "isPinned": false
  }'
```

**Get All Notes:**
```bash
# All notes
curl http://backend:3001/notes

# Search
curl "http://backend:3001/notes?search=meeting"

# Filter by category
curl "http://backend:3001/notes?category=Work"

# Combined
curl "http://backend:3001/notes?search=project&category=Work"
```

**Update Note:**
```bash
curl -X PUT http://backend:3001/notes/1 \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Updated Title",
    "content": "Updated content",
    "isPinned": true
  }'
```

**Delete Note:**
```bash
curl -X DELETE http://backend:3001/notes/1
```

### UI Features

- **Grid Layout** - Responsive card-based design
- **Pinned Notes** - Pin icon, sorted to top, gold highlight
- **Categories** - Color-coded badges (Work=blue, Personal=green, Ideas=purple)
- **Search** - Real-time search in title and content
- **Filter** - Category dropdown filter
- **Create/Edit** - Modal form with validation
- **Delete** - Confirmation prompt
- **Timestamps** - Human-readable dates

## Testing

### Backend Testing

```bash
cd apps/backend

# Unit tests
npm run test

# E2E tests
npm run test:e2e

# Test coverage
npm run test:cov
```

### Frontend Testing

```bash
cd apps/frontend

# Run tests (if configured)
npm run test

# Type check
npm run type-check
```

### Integration Testing

Test backend API with frontend:

```bash
# Start backend
cd apps/backend && npm run start:dev &

# Start frontend
cd apps/frontend && npm run dev &

# Manual testing at http://localhost:3000
# Or automated E2E tests with Playwright/Cypress
```

## Adding New Features

### Backend: Add New Entity

1. Create entity in `src/[feature]/[entity].entity.ts`
2. Create service in `src/[feature]/[entity].service.ts`
3. Create controller in `src/[feature]/[entity].controller.ts`
4. Create DTOs in `src/[feature]/[entity].dto.ts`
5. Create module in `src/[feature]/[entity].module.ts`
6. Import module in `app.module.ts`

### Frontend: Add New Component

1. Create component in `app/components/[Component].tsx`
2. Import in parent component or page
3. Add styling in `app/styles.css` or component-level CSS

## Troubleshooting

### Backend Issues

**Database connection fails:**
```bash
# Check environment variables
cat .env

# Test connection
psql -h $DB_HOST -U $DB_USERNAME -d $DB_NAME

# Check TypeORM logs
npm run start:dev  # Check console output
```

**Module not found:**
```bash
# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install
```

### Frontend Issues

**API calls fail:**
```bash
# Check backend URL
cat .env.local

# Check backend is running
curl http://localhost:3001/health

# Check CORS settings in backend
```

**Build fails:**
```bash
# Clear Next.js cache
rm -rf .next
npm run build
```

## Production Considerations

### Backend

- Use environment variables for all config
- Enable error logging (Winston, Pino)
- Set up health checks
- Configure CORS properly
- Use connection pooling for database
- Implement rate limiting
- Add request logging
- Use helmet for security headers

### Frontend

- Optimize images
- Enable static generation where possible
- Set up error boundaries
- Implement loading states
- Add SEO metadata
- Configure CSP headers
- Minimize bundle size
- Enable compression

## Monitoring

### Backend Monitoring

```bash
# PM2 monitoring
pm2 status
pm2 logs notes-backend
pm2 monit

# Health check
curl http://backend:3001/health
```

### Frontend Monitoring

```bash
# PM2 monitoring
pm2 status
pm2 logs notes-frontend
pm2 monit

# Check if accessible
curl http://frontend:3000
```

## Version Control

These applications should be:
- ✅ Version controlled independently
- ✅ Tagged with semantic versions
- ✅ Documented with changelogs
- ✅ Tested before deployment
- ✅ Built before copying to servers

**Git workflow:**
```bash
# Make changes to app
cd apps/backend
# ... make changes ...

# Test locally
npm run test
npm run build

# Commit
git add .
git commit -m "feat: add new feature"

# Deploy with Ansible
cd ../../ansible
ansible-playbook deploy-backend.yml
```

## Next Steps

1. **Add tests** - Unit and integration tests
2. **Add migrations** - Database schema versioning
3. **Add authentication** - User login/JWT
4. **Add authorization** - Role-based access
5. **Add pagination** - For large datasets
6. **Add caching** - Redis for performance
7. **Add CI/CD** - Automated testing and deployment
8. **Add monitoring** - Application performance monitoring

## Additional Resources

- [NestJS Documentation](https://docs.nestjs.com/)
- [Next.js Documentation](https://nextjs.org/docs)
- [TypeORM Documentation](https://typeorm.io/)
- [React Documentation](https://react.dev/)
- [PM2 Documentation](https://pm2.keymetrics.io/)
