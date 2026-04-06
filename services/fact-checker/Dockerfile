# Build context: repo root
# docker build -f services/fact-checker/Dockerfile .

# ── Stage 1: build shared types ───────────────────────────────────────────
FROM node:20-alpine AS types-builder
WORKDIR /types
COPY types/package*.json ./
RUN npm ci
COPY types/ ./
RUN npm run build

# ── Stage 2: build fact-checker service ──────────────────────────────────
FROM node:20-alpine AS service-builder
WORKDIR /app

# Install deps first (cached layer)
COPY services/fact-checker/package*.json ./
COPY --from=types-builder /types /types
RUN npm ci --legacy-peer-deps

# Copy source and compile
COPY services/fact-checker/tsconfig*.json services/fact-checker/nest-cli.json ./
COPY services/fact-checker/src ./src
RUN npm run build

# ── Stage 3: production image ─────────────────────────────────────────────
FROM node:20-alpine AS production
WORKDIR /app
ENV NODE_ENV=production

COPY --from=service-builder /app/dist ./dist
COPY --from=service-builder /types /types
COPY services/fact-checker/package*.json ./
RUN npm ci --legacy-peer-deps --omit=dev

EXPOSE 8080
ENV PORT=8080

CMD ["node", "dist/main"]
