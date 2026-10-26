# pack-rat-deploy

Runs PackRat in production on the home server (`packrat`), reached only over Tailscale at `https://packrat.<tailnet>.ts.net`.

The images are built by CI in [pack-rat-backend](https://github.com/MarcoSchoch1/pack-rat-backend) and [pack-rat-frontend](https://github.com/MarcoSchoch1/pack-rat-frontend) on every push to `main` and published to GHCR. This repo only runs them.

| File | Purpose |
|---|---|
| `compose.yaml` | `postgres`, `backend`, `frontend` (Nginx serving Angular, proxies `/api`) |
| `.env.example` | All config keys. Copy to `.env` (gitignored) on the server |
| `backup.sh` | Nightly `pg_dump` to `/srv/backups`, keeps 14 days |

Full runbook (one-time setup, config table, restore): [pack-rat-docs/deployment/deployment.md](https://github.com/MarcoSchoch1/pack-rat-docs/blob/main/deployment/deployment.md). Decisions: ADR-023 to ADR-028.

## First start

```sh
git clone https://github.com/MarcoSchoch1/pack-rat-deploy.git ~/pack-rat-deploy
cd ~/pack-rat-deploy && cp .env.example .env && nano .env
docker compose up -d
docker compose logs -f backend
```

Log in as `ADMIN_USERNAME`, then delete `ADMIN_PASSWORD` from `.env` and run `docker compose up -d` again.

Backups, via `crontab -e`:

```
0 3 * * * /home/<user>/pack-rat-deploy/backup.sh >> /srv/backups/backup.log 2>&1
```

## Update

```sh
cd ~/pack-rat-deploy && git pull
./backup.sh                        # always first: ddl-auto=update may change the schema
docker compose pull && docker compose up -d
docker image prune -f
```

**Rollback:** set `BACKEND_TAG` / `FRONTEND_TAG` in `.env` to the last good `sha-…` tag, then `docker compose up -d`. Schema changes aren't rolled back; restore the pre-deploy dump if needed.

## Restore

Overwrites the current data:

```sh
docker compose stop backend
docker compose exec -T postgres pg_restore -U packrat -d packrat --clean --if-exists < /srv/backups/packrat-YYYY-MM-DD.dump
docker compose start backend
```
