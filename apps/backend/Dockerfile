# Use official Node.js LTS image
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /usr/src/app

# Install dependencies
COPY package.json package-lock.json ./
RUN npm ci --silent

# Copy source code
COPY tsconfig.json ./
COPY src ./src

# Build Nest.js app
RUN npm run build

# Use a smaller image for runtime
FROM node:20-alpine AS runner
WORKDIR /usr/src/app

# Copy only the built app and package files
COPY package.json package-lock.json ./
COPY --from=builder /usr/src/app/dist ./dist

# Install production dependencies only
RUN npm ci --omit=dev --silent

# Expose port
EXPOSE 3001

# Set environment variables defaults (can be overridden)
ENV PORT=3001
ENV DATABASE_HOST=localhost
ENV DATABASE_PORT=5432
ENV DATABASE_USER=dbadmin
ENV DATABASE_PASSWORD=password
ENV DATABASE_NAME=notesdb

# Start the app
CMD ["node", "dist/main.js"]
