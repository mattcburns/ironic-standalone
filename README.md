# Ironic Container

A single container image for OpenStack Ironic that can run as an **API server**, **conductor**, or perform **database migrations**, controlled by the `IRONIC_ROLE` environment variable. Designed to be configured entirely via a mounted `ironic.conf` file.

## Image & Tags

Published to GitHub Container Registry:

```
ghcr.io/mattcburns/ironic-standalone
```

Tag strategy (from `docker-publish.yml`):

- `master` (latest state of the default branch)
- `vX.Y.Z` (full semver tag you push)
- `X.Y` and `X` convenience semver tags
- Commit SHA tag (e.g. `sha-<shortsha>`) for reproducibility

## Configuration

The container expects a standard `ironic.conf` mounted at:

```
/etc/ironic/ironic.conf
```

This is a standard OpenStack Ironic configuration file. The container makes no assumptions about its contents -- configure database, RabbitMQ, auth strategy, hardware types, etc. as needed for your environment.

### Optional Mounts

| Path | Purpose |
|---|---|
| `/etc/ironic/ironic.conf` | **Required.** Main Ironic configuration file. |
| `/etc/ironic/htpasswd` | HTTP basic auth credentials (if `auth_strategy = http_basic`). |
| `/etc/ironic/conductor-override.conf` | Per-instance conductor overrides (host, workers, conductor_group). Automatically loaded if present. |
| `/var/log/ironic` | Ironic log directory. |
| `/shared/html` | HTTP-served files for virtual media boot and deploy images. |

### Environment Variables

| Variable | Default | Description |
|---|---|---|
| `IRONIC_ROLE` | `api` | Container role: `api`, `conductor`, or `dbsync`. |
| `IRONIC_CONFIG` | `/etc/ironic/ironic.conf` | Path to the main config file inside the container. |
| `DBSYNC_CMD` | `upgrade` | Database sync command (used when `IRONIC_ROLE=dbsync`). Set to `create_schema` for initial setup. |

## Usage

### Database Initialization

Run database migrations before starting API or conductor services:

Replace `/path/to/your` with the actual host path for your Ironic configuration.

```bash
docker run --rm \
  --network ironic-network \
  -v /path/to/your/ironic.conf:/etc/ironic/ironic.conf:ro \
  -e IRONIC_ROLE=dbsync \
  ghcr.io/mattcburns/ironic-standalone:master
```

For initial schema creation (first-time setup):

```bash
docker run --rm \
  --network ironic-network \
  -v /path/to/your/ironic.conf:/etc/ironic/ironic.conf:ro \
  -e IRONIC_ROLE=dbsync \
  -e DBSYNC_CMD=create_schema \
  ghcr.io/mattcburns/ironic-standalone:master
```

### API Server

```bash
docker run -d --name ironic-api \
  --network ironic-network \
  -v /path/to/your/ironic.conf:/etc/ironic/ironic.conf:ro \
  -v /path/to/your/htpasswd:/etc/ironic/htpasswd:ro \
  -v /path/to/your/logs:/var/log/ironic \
  -p 6385:6385 \
  -e IRONIC_ROLE=api \
  ghcr.io/mattcburns/ironic-standalone:master
```

### Conductor

```bash
docker run -d --name ironic-conductor-1 \
  --hostname ironic-conductor-1 \
  --network ironic-network \
  -v /path/to/your/ironic.conf:/etc/ironic/ironic.conf:ro \
  -v /path/to/your/htpasswd:/etc/ironic/htpasswd:ro \
  -v /path/to/your/conductor-1.conf:/etc/ironic/conductor-override.conf:ro \
  -v /path/to/your/logs:/var/log/ironic \
  -v /path/to/your/http_images:/shared/html \
  -e IRONIC_ROLE=conductor \
  ghcr.io/mattcburns/ironic-standalone:master
```

The conductor override config is automatically loaded if present at `/etc/ironic/conductor-override.conf`. A typical override sets the conductor hostname and worker pool size:

```ini
[DEFAULT]
host = ironic-conductor-1

[conductor]
workers_pool_size = 128
```

### Multiple Conductors

Scale by running additional conductor containers with unique names, hostnames, and override configs:

```bash
docker run -d --name ironic-conductor-2 \
  --hostname ironic-conductor-2 \
  --network ironic-network \
  -v /path/to/your/ironic.conf:/etc/ironic/ironic.conf:ro \
  -v /path/to/your/htpasswd:/etc/ironic/htpasswd:ro \
  -v /path/to/your/conductor-2.conf:/etc/ironic/conductor-override.conf:ro \
  -v /path/to/your/logs:/var/log/ironic \
  -v /path/to/your/http_images:/shared/html \
  -e IRONIC_ROLE=conductor \
  ghcr.io/mattcburns/ironic-standalone:master
```

## Ironic Version

This image installs Ironic and its dependencies based on the versions specified in `requirements.txt`. Currently:

*   `ironic==35.0.1`
*   `python-ironicclient==6.1.0`
*   `PyMySQL`

## Building

```bash
docker build -t ironic .
```
