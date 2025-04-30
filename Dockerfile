# Dockerfile
FROM rust:1.84 as builder

# Build arguments
ARG ANKI_VERSION

# Install build dependencies and anki-sync-server
RUN apt-get update && apt-get install -y protobuf-compiler \
    && rm -rf /var/lib/apt/lists/* \
    && cargo install --git https://github.com/ankitects/anki.git --branch main --tag ${ANKI_VERSION} anki-sync-server \
    && rm -rf /usr/local/cargo/registry

FROM debian:stable-slim

# Add labels
LABEL maintainer="Anki Sync Server Docker Maintainers"
LABEL version="${ANKI_VERSION}"
LABEL description="Anki Sync Server Docker Image"
LABEL org.opencontainers.image.source="https://github.com/kenyon-wong/anki-sync-server-docker.git"

# Setup runtime environment
ENV DEFAULT_SYNC_BASE=/opt/anki.d/sync.d
RUN apt-get update && apt-get install -y \
    ca-certificates \
    tzdata \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -r anki \
    && useradd -r -g anki -d ${DEFAULT_SYNC_BASE} -s /bin/false anki \
    && mkdir -p ${DEFAULT_SYNC_BASE} \
    && chown -R anki:anki ${DEFAULT_SYNC_BASE} \
    && chmod 755 ${DEFAULT_SYNC_BASE}

# Copy anki-sync-server binary
COPY --from=builder /usr/local/cargo/bin/anki-sync-server /usr/local/bin/anki-sync-server

CMD ["anki-sync-server"]
