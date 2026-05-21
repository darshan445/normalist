# Deployment (Docker Compose)

NormaList deploys the **Rails API only** via `Dockerfile` + `docker-compose.yml`. The Next.js frontend is hosted separately (e.g. Vercel).

## Prerequisites

- Docker and Docker Compose v2
- `RAILS_MASTER_KEY` from `config/master.key`
- Shopify app credentials and public URLs

## Setup

```bash
docker compose --env-file .env.docker up -d --build
```

## Services

| Service   | Role                                      |
|-----------|-------------------------------------------|
| `web`     | Rails API (Thruster on container port 80) |
| `sidekiq` | Background jobs                           |
| `db`      | PostgreSQL 17 + pgvector (`pgvector/pgvector:pg17`) |
| `redis`   | Valkey 8                                  |

## Database and Redis (`.env.docker`)

### Production on your instance (use Compose `db` + `redis`)

```env
DATABASE_HOST=db
DATABASE_PORT=5432
DATABASE_NAME=normalist_production
DATABASE_USERNAME=normalist
DATABASE_PASSWORD=<strong password>
REDIS_URL=redis://redis:6379/0
```

`db` is the Docker service name — not `localhost`. `DATABASE_USERNAME` / `DATABASE_PASSWORD` must match what the `db` container is created with.

### Local machine: Docker app → Postgres on the host

Postgres running on your laptop (`localhost:5432`, user `postgres`) is **not** reachable as `localhost` from inside a container.

```env
DATABASE_HOST=host.docker.internal
DATABASE_PORT=5432
DATABASE_NAME=normalist_development
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=postgres
REDIS_URL=redis://host.docker.internal:6379/0
```

On Linux, if `host.docker.internal` fails, add to the `web` / `sidekiq` service in `docker-compose.yml`:

```yaml
extra_hosts:
  - "host.docker.internal:host-gateway"
```

Or run only Postgres on the host and use the full Compose stack on the server (recommended): same `.env.docker` pattern as production, with `DATABASE_HOST=db` on the instance.

### Local machine: Rails without Docker

Use `DATABASE_HOST=localhost` in `.env` (not `.env.docker`).

- **API:** `http://localhost:$WEB_PORT`
- **Health:** `/up`
- **Storage (dev):** disk under `storage/` (`config.active_storage.service = :local`)
- **Storage (production):** Cloudflare R2 via `config/storage.yml` → `cloudflare_r2` (set `CLOUDFLARE_R2_*` in `.env.docker` / `.kamal/secrets`)

On first boot, `web` runs `db:prepare` (migrate/create DB).

## Production notes

- Rails runs with `RAILS_ENV=production` and `force_ssl`. Terminate TLS at a reverse proxy (Caddy, nginx, Traefik) in front of port 3000.
- Point `HOST` at the proxy’s public HTTPS URL (e.g. `https://api.normalist.space`).
- Reinstall the Shopify app or re-auth after changing `HOST` so webhooks re-register.
- Vercel frontend must set `NEXT_PUBLIC_API_URL=https://api.normalist.space` so OAuth opens on the API host (not `normalist.vercel.app/login`).

## Postgres collation warning

If you switched Postgres images or moved a data volume between hosts, you may see a **collation version mismatch**. Reset the Compose volume once (destroys DB data):

```bash
docker compose --env-file .env.docker down
docker volume rm normalist_postgres_data
docker compose --env-file .env.docker up -d --build
```

## Useful commands

```bash
docker compose --env-file .env.docker logs -f web
docker compose --env-file .env.docker logs -f sidekiq
docker compose --env-file .env.docker exec web bin/rails console
docker compose --env-file .env.docker down
```

## Build image only

```bash
docker build -t normalist .
```

---

## Kamal (production server)

Kamal uses the **same `Dockerfile`**, env vars, and images as Compose. Hostnames differ:

| Compose (`.env.docker`) | Kamal (`config/deploy.yml`) |
|-------------------------|-----------------------------|
| `DATABASE_HOST=db` | `DATABASE_HOST=normalist-db` |
| `REDIS_URL=redis://redis:6379/0` | `REDIS_URL=redis://normalist-redis:6379/0` |

Keep **`.env.docker` unchanged** for Compose. For Kamal, copy values into **`.kamal/secrets`** (see `.kamal/secrets.example`). Set `POSTGRES_PASSWORD` to the same value as `DATABASE_PASSWORD`.

### First-time setup

```bash
bundle install
bundle binstubs kamal   # creates bin/kamal (or use: bundle exec kamal …)
cp .kamal/secrets.example .kamal/secrets
# edit .kamal/secrets — same values as .env.docker + KAMAL_REGISTRY_PASSWORD

kamal accessory boot db
kamal accessory boot redis
kamal setup
kamal deploy
```

### Server: 216.128.153.117

- HTTPS: `https://api.normalist.space` (Kamal proxy)
- Do **not** run Compose and Kamal on the same host at once (port conflicts on 5432, 6379, 80/443). Stop Compose before Kamal:

```bash
docker compose --env-file .env.docker down
```

### Useful Kamal commands

```bash
kamal deploy
kamal app logs -f
kamal app exec -r job --interactive bundle exec sidekiq -V
kamal collation
kamal accessory reboot db
```
