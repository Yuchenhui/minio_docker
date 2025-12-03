#!/usr/bin/env bash

# MinIO 认证配置（如未设置则自动生成）
declare -x MINIO_ROOT_USER
[[ -z "${MINIO_ROOT_USER}" ]] && MINIO_ROOT_USER="$(< /dev/urandom tr -dc A-Z0-9 | head -c20)"

declare -x MINIO_ROOT_PASSWORD
[[ -z "${MINIO_ROOT_PASSWORD}" ]] && MINIO_ROOT_PASSWORD="$(< /dev/urandom tr -dc _A-Za-z0-9+- | head -c40)"

# 数据目录（docker-compose 通过 command 使用 /data）
declare -x MINIO_START_DIRECTORY
[[ -z "${MINIO_START_DIRECTORY}" ]] && MINIO_START_DIRECTORY="/data"

# 服务监听地址
declare -x MINIO_ADDRESS
[[ -z "${MINIO_ADDRESS}" ]] && MINIO_ADDRESS="0.0.0.0:9000"

declare -x MINIO_CONSOLE_ADDRESS
[[ -z "${MINIO_CONSOLE_ADDRESS}" ]] && MINIO_CONSOLE_ADDRESS="0.0.0.0:9001"

# 内部端口（用于 healthcheck，支持 docker-compose 环境变量覆盖）
declare -x MINIO_INTERNAL_PORT
[[ -z "${MINIO_INTERNAL_PORT}" ]] && MINIO_INTERNAL_PORT="9000"

# 跳过 chown 操作（大量文件时可提升启动速度）
declare -x MINIO_SKIP_CHOWN
[[ -z "${MINIO_SKIP_CHOWN}" ]] && MINIO_SKIP_CHOWN="false"

# Healthcheck 配置（使用 127.0.0.1 确保容器内可访问）
declare -x MINIO_HEALTHCHECK_URL
[[ -z "${MINIO_HEALTHCHECK_URL}" ]] && MINIO_HEALTHCHECK_URL="http://127.0.0.1:${MINIO_INTERNAL_PORT}/minio/health/live"

declare -x MINIO_HEALTHCHECK_CODE
[[ -z "${MINIO_HEALTHCHECK_CODE}" ]] && MINIO_HEALTHCHECK_CODE="200"

true
