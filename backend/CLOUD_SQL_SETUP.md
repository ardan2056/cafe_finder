# Cloud SQL / Cloud SQL Auth Proxy (local dev)

This file explains how to run Cloud SQL Auth Proxy locally for connecting to a Cloud SQL Postgres instance, or how to run a local Postgres for development.

Using the provided `docker-compose.yml`:

1. Place your service account JSON into `backend/cloudsql/service-account.json` (this file is in `.dockerignore`).
2. Set the `CLOUDSQL_CONNECTION_NAME` environment variable to the instance connection name: `project:region:instance`.
3. Start the auth proxy:

```bash
cd backend
CLOUDSQL_CONNECTION_NAME=project:region:instance docker compose up cloudsql-proxy
```

This will expose a Postgres-compatible socket on port 5432 (container). The compose file maps container port 5432 to host 5432.

Local Postgres fallback
-----------------------
If you prefer to run a local Postgres instance for dev without using Cloud SQL, start the `postgres-local` service:

```bash
cd backend
docker compose up postgres-local
```

Then set `DATABASE_URL=postgres://dev:dev@localhost:5433/cafefinder` and run `npm run migrate`.
