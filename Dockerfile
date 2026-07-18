# syntax=docker/dockerfile:1

# ---- Builder stage ----
FROM rust:1.97-bookworm AS builder

ARG ANKI_VERSION

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends protobuf-compiler \
    && rm -rf /var/lib/apt/lists/*

# Build anki-sync-server from the official source
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/usr/local/cargo/git \
    cargo install --git https://github.com/ankitects/anki.git \
    --tag ${ANKI_VERSION} anki-sync-server

# ---- Runtime stage ----
FROM debian:bookworm-slim

# Re-declare ANKI_VERSION (ARG scope does not carry across stages)
ARG ANKI_VERSION

LABEL org.opencontainers.image.title="Anki Sync Server" \
      org.opencontainers.image.description="Anki Sync Server Docker Image" \
      org.opencontainers.image.version="${ANKI_VERSION}" \
      org.opencontainers.image.source="https://github.com/kenyon-wong/anki-syncd.git" \
      org.opencontainers.image.authors="Anki Sync Server Docker Maintainers" \
      org.opencontainers.image.licenses="AGPL-3.0-or-later"

ENV DEFAULT_SYNC_BASE=/opt/anki.d/sync.d

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -r anki \
    && useradd -r -g anki -d ${DEFAULT_SYNC_BASE} -s /bin/false anki \
    && mkdir -p ${DEFAULT_SYNC_BASE} \
    && chown -R anki:anki ${DEFAULT_SYNC_BASE} \
    && chmod 755 ${DEFAULT_SYNC_BASE}

COPY --from=builder /usr/local/cargo/bin/anki-sync-server /usr/local/bin/anki-sync-server

USER anki
WORKDIR ${DEFAULT_SYNC_BASE}

CMD ["anki-sync-server"]