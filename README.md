# FlowFi

Monorepo:

- `packages/backend` — Laravel API (PHP 8.3, SQLite, Sanctum)
- `platform/frontend` — Flutter app (web-enabled)

## Run with Docker

```sh
docker compose up --build
```

- API: http://localhost:8000 (e.g. `GET /api/user`, Sanctum-protected)
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

### Notes

- The API base URL from Flutter web code must be `http://localhost:8000` —
  the JS runs in your host browser, so compose service names don't resolve.
- CORS for `http://localhost:5050` is configured in
  `packages/backend/config/cors.php` via `FRONTEND_URL` in `.env`.
- SQLite database lives at `packages/backend/database/database.sqlite`
  (bind-mounted, survives `docker compose down`). Migrations run on API start.
