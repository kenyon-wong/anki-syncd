# Dockerfile
FROM rust:1.75-alpine AS builder

RUN set -aeux && apk add --no-cache binutils git musl-dev protobuf-dev

RUN set -aeux \
    && cargo install --git https://github.com/ankitects/anki.git --tag 24.04 anki-sync-server \
    && rm -rf /tmp/cargo-install*

RUN set -aeux \
    && mkdir -p /rootfs/ \
    && cp --parents $(which anki-sync-server) /rootfs/ \
    && cp --parents `ldd $(which anki-sync-server) | awk '{if (match($1,"/")){print $1}}')` /rootfs/ \
    && strip $(find /rootfs/ -type f -iname "*")

FROM alpine:latest

# Init system envs
ENV \
    LANG=C.UTF-8 \
    TZ=Asia/Shanghai \
    SYNC_BASE=/opt/anki.d/sync.d

# Set work directory
WORKDIR /opt/anki.d

# Copy anki-sync-server
COPY --from=builder /rootfs/ /

# Set system environments
RUN set -aeux && sed -i "s/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g" /etc/apk/repositories
RUN set -aeux && apk add --no-cache ca-certificates tzdata

# Set the Timezone
RUN set -aeux \
    && ln -sf $(echo /usr/share/zoneinfo/${TZ}) /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && ln -sf /usr/local/cargo/bin/anki-sync-server /usr/local/bin/anki-sync-server

CMD ["anki-sync-server"]
