# Builder stage
FROM node:20-alpine AS builder

WORKDIR /usr/src/app

# Install dependencies
COPY package.json package-lock.json ./
RUN npm ci --silent

# Copy source
COPY tsconfig.json next.config.js ./
COPY app ./app
COPY public ./public

# Build Next.js app
RUN npm run build

# Runtime stage (production)
FROM node:20-alpine AS runner
WORKDIR /usr/src/app

# Install production dependencies
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --silent

# Copy built files from builder
COPY --from=builder /usr/src/app/.next ./.next
COPY --from=builder /usr/src/app/public ./public
COPY --from=builder /usr/src/app/app ./app

# Expose port
EXPOSE 3000

# Set backend API URL default (overridden by Ansible)
ENV BACKEND_API_URL=http://localhost:3001
ENV PORT=3000

# Start Next.js server
CMD ["npx", "next", "start", "-p", "3000"]
