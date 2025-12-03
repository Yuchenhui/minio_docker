# ============================================
# Stage 1: Extract old Console frontend (with full UI)
# ============================================
FROM golang:1.24-alpine AS console-extract

# Last version with full admin UI (Identity, Access, Settings, etc.)
ENV CONSOLE_VERSION=RELEASE.2025-04-22T22-12-26Z

RUN apk add --no-cache git

# Clone old MinIO to extract its console dependency version
RUN git clone --depth 1 -b ${CONSOLE_VERSION} https://github.com/minio/minio.git /old-minio

# Get the console version used by old MinIO
WORKDIR /old-minio
RUN CONSOLE_VER=$(grep 'github.com/minio/console' go.mod | awk '{print $2}') && \
    echo "Console version: $CONSOLE_VER" && \
    git clone --depth 1 -b v${CONSOLE_VER#v} https://github.com/minio/console.git /console || \
    git clone https://github.com/minio/console.git /console && \
    cd /console && git checkout ${CONSOLE_VER#v} 2>/dev/null || true

# ============================================
# Stage 2: Build new MinIO backend + old Console frontend
# ============================================
FROM golang:1.24-alpine AS build

# Latest MinIO version (with CVE fixes and security updates)
ENV MINIO_VERSION=RELEASE.2025-10-15T17-29-55Z

RUN apk add --no-cache bash perl git make

# Configure git for large repositories
RUN git config --global http.postBuffer 524288000 && \
    git config --global http.lowSpeedLimit 1000 && \
    git config --global http.lowSpeedTime 300

# Clone latest MinIO source code
RUN git clone --depth 1 -b ${MINIO_VERSION} https://github.com/minio/minio.git /srv/app/src

# Copy old console (with full UI)
COPY --from=console-extract /console /srv/console

# Modify MinIO's go.mod to use old console instead of the new one
WORKDIR /srv/app/src
RUN echo 'replace github.com/minio/console => /srv/console' >> go.mod

# Set Go proxy and download dependencies (with retry)
ENV GOPROXY=https://goproxy.cn,https://proxy.golang.org,direct
RUN for i in 1 2 3 4 5; do go mod tidy && break || sleep 10; done

# Build and install (set MINIO_RELEASE to show correct version)
ENV MINIO_RELEASE=RELEASE
RUN make install

# ============================================
# Stage 3: Runtime image
# ============================================
FROM alpine:3.21

VOLUME ["/data"]
EXPOSE 9000 9001

WORKDIR /var/lib/minio

# Install runtime dependencies and create user
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
        bash \
        curl \
        su-exec && \
    mkdir -p /var/lib/minio /data && \
    addgroup -g 1000 minio && \
    adduser -u 1000 -D -h /var/lib/minio -G minio -s /bin/bash minio && \
    chown -R minio:minio /var/lib/minio /data && \
    rm -rf /var/cache/apk/*

# Copy minio binary from build stage
COPY --from=build /go/bin/minio /usr/bin/minio

# Copy overlay scripts
COPY ./overlay /

# Set script permissions
RUN chmod +x /usr/bin/container \
             /usr/bin/entrypoint \
             /usr/bin/healthcheck \
             /etc/entrypoint.d/*.sh \
             /etc/container.d/*.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD /usr/bin/healthcheck

# Entrypoint
ENTRYPOINT ["/usr/bin/container"]
