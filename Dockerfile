# Dockerfile
FROM rust:1.75-alpine AS builder

RUN set -aeux && apk add --no-cache binutils git musl-dev protobuf-dev

RUN set -aeux \
    && cargo install --git https://github.com/ankitects/anki.git --tag 24.06.2 anki-sync-server \
    && rm -rf /tmp/cargo-install*

# RUN set -aeux \
RUN set -aeux \
    && mkdir /rootfs \
    && cp --parents $(which anki-sync-server) /rootfs/ \
    && cp --parents $(ldd "$(which anki-sync-server)" | awk '{if ( match($1,"/") ) {print $1}}') /rootfs/ \
    && strip $(find /rootfs/ -type f)

FROM alpine:latest

# Init system envs
ENV \
    PATH="${PATH}:/usr/local/cargo/bin" \
    LANG=C.UTF-8 \
    TZ=Asia/Shanghai \
    SYNC_BASE=/opt/anki.d/sync.d

# Set work directory
WORKDIR /opt/anki.d

# Set system environments
# RUN set -aeux && sed -i "s/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g" /etc/apk/repositories
RUN set -aeux && apk add --no-cache ca-certificates tzdata

# Set the Timezone
RUN set -aeux \
    && ln -sf "/usr/share/zoneinfo/${TZ}" /etc/localtime

# Copy anki-sync-server
COPY --from=builder /rootfs/ /

CMD ["anki-sync-server"]
