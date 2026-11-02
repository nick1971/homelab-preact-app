# --- Stage 1: Build the Preact Frontend ---
FROM node:20-alpine AS builder

WORKDIR /app

# Copy dependency definitions and install
COPY package*.json ./
RUN npm ci

# Copy source files and build production static bundle
COPY . .
RUN npm run build

# --- Stage 2: Final PocketBase Container ---
FROM alpine:latest

# Install runtime dependencies for PocketBase
RUN apk add --no-cache ca-certificates tzdata unzip wget

WORKDIR /pb

# Download and extract PocketBase
ARG PB_VERSION=0.22.20
ARG TARGETARCH=amd64
RUN wget https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_${TARGETARCH}.zip \
    && unzip pocketbase_${PB_VERSION}_linux_${TARGETARCH}.zip \
    && rm pocketbase_${PB_VERSION}_linux_${TARGETARCH}.zip

# Copy the built Preact assets from Stage 1 into PocketBase's public folder
COPY --from=builder /app/dist /pb/pb_public

# Expose PocketBase port
EXPOSE 8090

# Start PocketBase
CMD ["/pb/pocketbase", "serve", "--http=0.0.0.0:8090"]
