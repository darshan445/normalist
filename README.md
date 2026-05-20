# NormaList

Rails API for supplier file ingestion, mapping, and Shopify inventory sync. The embedded admin UI lives in `frontend/` (Next.js).

## Development

See `.env.example` for local environment variables. Run Rails on port 3000 and the frontend on 3001.

## Deployment

Production uses **Docker Compose** only:

```bash
docker compose --env-file .env.docker up -d --build
```

See [DEPLOYMENT.md](DEPLOYMENT.md) for full details.

## Tests

```bash
bundle exec rspec
```
