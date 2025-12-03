FROM golang:1.24-alpine AS build

# 可通过 --build-arg 指定版本，默认使用最新稳定版
ARG MINIO_VERSION=RELEASE.2025-05-24T17-08-30Z

RUN apk add --no-cache perl git make bash && \
    git clone --depth 1 -b ${MINIO_VERSION} https://github.com/minio/minio.git /srv/app/src && \
    cd /srv/app/src && \
    make build && \
    mv /srv/app/src/minio /srv/app/minio

# ============================================
# 运行时镜像
# ============================================
FROM alpine:3.21

ARG MINIO_VERSION=RELEASE.2025-05-24T17-08-30Z

LABEL maintainer="JZXT Security <admin@jzxtseccorp.com>" \
      version="${MINIO_VERSION}" \
      description="MinIO Object Storage Server (self-built)"

# 安装运行时依赖
RUN apk update && \
    apk add --no-cache \
        bash \
        curl \
        su-exec \
        ca-certificates && \
    # 创建 minio 用户和组
    addgroup -g 1000 minio && \
    adduser -u 1000 -D -h /var/lib/minio -G minio -s /bin/bash minio && \
    # 创建数据目录
    mkdir -p /var/lib/minio /data && \
    chown -R minio:minio /var/lib/minio /data && \
    # 清理缓存
    rm -rf /var/cache/apk/*

# 从构建阶段复制 minio 二进制文件
COPY --from=build /srv/app/minio /usr/bin/minio

# 复制 overlay 脚本
COPY ./overlay /

# 设置脚本执行权限
RUN chmod +x /usr/bin/container \
             /usr/bin/entrypoint \
             /usr/bin/healthcheck \
             /etc/entrypoint.d/*.sh \
             /etc/container.d/*.sh

# 数据卷和端口
VOLUME ["/data"]
EXPOSE 9000 9001

WORKDIR /var/lib/minio

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD /usr/bin/healthcheck

# 默认入口点和命令
ENTRYPOINT ["/usr/bin/container"]
