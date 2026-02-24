# Invoice Ninja – Docker deployment

Deploy [Invoice Ninja](https://www.invoiceninja.com/) with Docker Compose. Suitable for **Dokploy**, Coolify, or any host that runs Docker Compose.

## Stack

| Service | Image | Role |
|--------|--------|------|
| **server** | `invoiceninja/invoiceninja-debian` | App (PHP-FPM, queue, scheduler) |
| **nginx** | `nginx:alpine` | Web server, proxies to app |
| **db** | `mariadb:11.8` | Database |
| **redis** | `valkey/valkey:alpine` | Cache, queue, sessions (Redis-compatible) |

Nginx config lives in `nginx/` (laravel.conf, invoiceninja.conf). The image’s `default.conf` is left as-is.

---

## Deploy with Dokploy

1. **Add the app**  
   Create a new application in Dokploy and connect this repo (Git or upload).

2. **Compose**  
   Use **Docker Compose** as the deployment type and point to this repo. Dokploy will use `docker-compose.yml` in the root.

3. **Environment**  
   Copy `.env.example` to `.env` (or add env vars in Dokploy’s UI). Set at least:
   - `APP_URL` – full URL (e.g. `https://invoice.yourdomain.com`)
   - `APP_KEY` – run `php artisan key:generate` and paste the `base64:...` value, or leave empty and let the image generate it on first run
   - `DB_*` / `MYSQL_*` – database credentials (must match)
   - `IN_USER_EMAIL` and `IN_PASSWORD` – first admin user (required on first run)
   - Mail and other options as in `.env.example`

4. **Domain**  
   In Dokploy, add a domain for this app and attach it to the **nginx** service.  
   - **Port:** `80`  
   - **Path / Internal path:** `/` (or leave empty for root)

5. **Volumes**  
   `storage_data`, `public_data`, and `mysql_data_mariadb` are defined in the compose file; Dokploy will create them. No extra volume setup is required unless you want to move DB or app data elsewhere.

6. **Start**  
   Deploy. The server starts after db and redis are up; it does not wait for their healthchecks, so startup is faster. The app will retry DB/Redis until they are ready.

---

## Deploy locally (Docker Compose)

```bash
cp .env.example .env
# Edit .env (APP_URL, APP_KEY, DB passwords, IN_USER_EMAIL, IN_PASSWORD, etc.)

docker compose up -d
```

- App: **nginx** on port 80 (or the port you map).
- Optional: set `TAG` to pin the app image, e.g. `TAG=v5.10.0 docker compose up -d`.

---

## Files

| Path | Purpose |
|------|--------|
| `docker-compose.yml` | Services: server, nginx, db, redis (Valkey) |
| `nginx/laravel.conf` | Nginx snippet (body size, fastcgi, gzip) |
| `nginx/invoiceninja.conf` | Nginx server block (PHP-FPM to `server:9000`) |
| `.env.example` | Example env; copy to `.env` and fill in |

---

## Notes

- **Valkey** is used instead of Redis; it’s protocol-compatible. The service is still named `redis` so `REDIS_HOST=redis` in `.env` works unchanged.
- **First run:** set `IN_USER_EMAIL` and `IN_PASSWORD` in `.env` so the image’s init script can create the first account.
- **HTTPS:** set `REQUIRE_HTTPS=true` and terminate SSL at Dokploy (or your reverse proxy). `APP_URL` must use `https://`.
- **Updates:** the server uses the official `invoiceninja/invoiceninja-debian` image. To upgrade, pull a new tag and set `TAG=...` (or use `latest`) and redeploy.

---

## Links

- [Invoice Ninja](https://www.invoiceninja.com/)
- [Invoice Ninja self-host docs](https://invoiceninja.github.io/docs/self-host/)
- [Dokploy](https://dokploy.com/)
