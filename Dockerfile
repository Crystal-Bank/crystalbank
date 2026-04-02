#
# Stage 1: Build Svelte frontend
#
FROM node:22-alpine AS frontend-builder

WORKDIR /app/frontend
COPY app/frontend/package.json ./
RUN npm install
COPY app/frontend/ ./
# Vite outDir is '../public', so output lands at /app/public
RUN npm run build

#
# Stage 2: Build Crystal binary
# Frontend assets are embedded at compile time via read_file, so they
# must be present in /app/public before crystal build runs.
#
FROM 84codes/crystal:1.19.1-ubuntu-24.04 AS crystal-builder

WORKDIR /app

# Copy application source including pre-installed lib/ (no registry access in this build environment)
COPY app/ ./

# Overlay built Svelte assets so Crystal can embed them at compile time
COPY --from=frontend-builder /app/public ./public

RUN crystal build src/server/start.cr --release -o crystalbank

#
# Stage 3: Minimal runtime image
#
FROM ubuntu:24.04 AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgc1 \
    libssl3 \
    libpq5 \
    libevent-2.1-7t64 \
    libpcre2-8-0 \
    libyaml-0-2 \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

COPY --from=crystal-builder /app/crystalbank /usr/local/bin/crystalbank

EXPOSE 3000

ENTRYPOINT ["/usr/local/bin/crystalbank"]
