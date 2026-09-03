# FlowFi

Monorepo:

- `packages/backend` — Laravel API (PHP 8.3, SQLite, Sanctum)
- `platform/frontend` — Flutter app (web-enabled)

## Run with Docker

```sh
docker compose up --build
```

- API: http://localhost:8000 (e.g. `GET /api/v1/users/{id}`, Sanctum-protected)
- Mailpit (catches every email the API sends): http://localhost:8025
- Flutter web: open http://localhost:5050 in Chrome on your machine — the
  container runs the dev server (`-d web-server`), the browser runs on the host.
  (Host port is 5050 because macOS AirPlay Receiver occupies 5000.)

First start is slow: the Flutter image is ~2 GB and the first `flutter run`
compiles everything. Later starts reuse the cached image and pub cache.

### Hot reload (Flutter)

```sh
docker compose attach web
```

Then press `r` (hot reload) or `R` (hot restart). Detach with `ctrl-p ctrl-q`.

Source is bind-mounted, so edit files normally in your editor.

### Signing in (OTP only, no passwords)

1. `POST /api/v1/auth/otp/request` with `{ "email": "you@example.com" }` → `202`.
2. Open Mailpit at http://localhost:8025 and read the 6-digit code.
3. `POST /api/v1/auth/otp/verify` with `{ "email", "code" }` → `200 { user, token }`.
   Unknown emails are registered on the spot; codes last 15 minutes and work once.
4. Send `Authorization: Bearer <token>` on protected routes.

Store `user.id` from step 3 alongside the token: it is the only time the API
hands out your own id, and `GET|PATCH|DELETE /api/v1/users/{id}` need it. Any
id other than your own answers `404`, never `403`, so the endpoint cannot be
used to discover which accounts exist.

### Notes

- The API base URL from Flutter web code must be `http://localhost:8000` —
  the JS runs in your host browser, so compose service names don't resolve.
- CORS for `http://localhost:5050` is configured in
  `packages/backend/config/cors.php` via `FRONTEND_URL` in `.env`.
- SQLite database lives at `packages/backend/database/database.sqlite`
  (bind-mounted, survives `docker compose down`). Migrations run on API start.
