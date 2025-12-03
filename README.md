# MinIO Docker Build

Custom MinIO Docker image with **latest backend** (security fixes) and **full admin UI** (before MinIO removed management features).

## Why This Project?

Starting from mid-2025, MinIO removed many admin UI features from their Console (Identity management, Access policies, Settings, etc.) for AGPL users. This project combines:

- **Backend**: Latest MinIO release (`RELEASE.2025-10-15T17-29-55Z`) with all CVE fixes
- **Frontend**: Old Console (`v1.7.6` from `RELEASE.2025-04-22T22-12-26Z`) with full admin UI

## Features

| Feature | Full UI (Dockerfile) | Lite (Dockerfile.lite) |
|---------|---------------------|------------------------|
| Object Browser | ✅ | ✅ |
| Bucket Management | ✅ | ✅ |
| Identity (Users/Groups) | ✅ | ❌ |
| Access (Policies) | ✅ | ❌ |
| Settings/Configuration | ✅ | ❌ |
| Monitoring | ✅ | ❌ |
| Latest Security Fixes | ✅ | ✅ |

## Build

### Full UI Version (Recommended)

```bash
docker build --network=host -f Dockerfile -t minio:fullui .
```

### Lite Version (Default MinIO UI)

```bash
docker build --network=host -f Dockerfile.lite -t minio:lite .
```

## Run

### Basic Usage

```bash
docker run -d \
    --name minio \
    --network host \
    -e MINIO_ROOT_USER=admin \
    -e MINIO_ROOT_PASSWORD=YourSecurePassword \
    -v /path/to/data:/data \
    minio:fullui \
    server /data --address :9000 --console-address :9001
```

### Custom Ports

```bash
docker run -d \
    --name minio \
    --network host \
    -e MINIO_ROOT_USER=admin \
    -e MINIO_ROOT_PASSWORD=YourSecurePassword \
    -v /path/to/data:/data \
    minio:fullui \
    server /data --address :19000 --console-address :19001
```

### Docker Compose

```yaml
version: '3.8'

services:
  minio:
    image: minio:fullui
    container_name: minio
    network_mode: host
    environment:
      MINIO_ROOT_USER: admin
      MINIO_ROOT_PASSWORD: YourSecurePassword
      TZ: Asia/Shanghai
    volumes:
      - ./data:/data
    command: server /data --address :9000 --console-address :9001
    restart: unless-stopped
```

## Access

After starting the container:

- **API Endpoint**: `http://localhost:9000`
- **Console UI**: `http://localhost:9001`

Login with the credentials you set in `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD`.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MINIO_ROOT_USER` | (required) | Admin username |
| `MINIO_ROOT_PASSWORD` | (required) | Admin password (min 8 chars) |
| `TZ` | `UTC` | Timezone |

## Verify Version

```bash
# Check MinIO version
docker exec minio minio --version

# Using mc client
docker run --rm --network host --entrypoint "" minio/mc:latest /bin/sh -c "
  mc alias set local http://127.0.0.1:9000 admin YourPassword
  mc admin info local
"
```

## Version Information

| Component | Version |
|-----------|---------|
| MinIO Backend | `RELEASE.2025-10-15T17-29-55Z` |
| Console Frontend | `v1.7.6` |
| Go | `1.24` |
| Base Image | `alpine:3.21` |

## References

- [dockhippie/minio](https://github.com/dockhippie/minio) - Docker image structure and overlay scripts inspiration
- [MinIO Official](https://github.com/minio/minio) - MinIO source code
- [MinIO Console](https://github.com/minio/console) - MinIO Console frontend

## License

MinIO is released under [GNU AGPLv3](https://www.gnu.org/licenses/agpl-3.0.html).
