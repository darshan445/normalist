# NormaList

Rails API for supplier file ingestion, mapping, and Shopify inventory sync. The embedded admin UI lives in `frontend/` (Next.js).

## Development

See `.env.example` for local environment variables. Run Rails on port 3000 and the frontend on 3001.

## Deployment

**Docker Compose** (local or full stack on a VM):

```bash
docker compose --env-file .env.docker up -d --build
```

**Kamal** (production server `216.128.153.117`, same image and env — see [DEPLOYMENT.md](DEPLOYMENT.md)):

```bash
bundle install && bundle binstubs kamal
bin/kamal setup && bin/kamal deploy
```

## Tests

```bash
bundle exec rspec
```
