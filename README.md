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

### Goals, categories and icons

All routes below need the bearer token.

- `GET /api/v1/icons` → `{ data: [{ category, icons: [...] }] }`. Icon names
  are Flutter Material `Icons` getter names (`savings`, `flight_takeoff`); the
  app keeps a `Map<String, IconData>` mirror and looks them up by name.
- `GET|POST /api/v1/goals`, `GET|PATCH|DELETE /api/v1/goals/{id}`. Body:
  `name`, `icon` (from the catalog), `color` (`#RRGGBB`, stored uppercase),
  `target_amount` (decimal, up to two places: `"1500.50"` or `1500.5`),
  `expires_at` (`YYYY-MM-DD`, optional). Amounts are stored as integer cents
  and always come back as a two-decimal string. `name` must be unique among
  your own live goals (`422` otherwise; case-sensitive, and a soft-deleted
  name can be reused). Goals are scoped to the caller: another user's id
  answers `404`, same as `users`.
- `GET|POST /api/v1/categories`, `GET|PATCH|DELETE /api/v1/categories/{id}`.
  Body: `name`, `icon`, `color` (same rules as goals, including the
  unique-name rule) and `limit_amount` (optional decimal cap, up to two
  places; `null` or omitted means no limit). Same scoping as goals: another
  user's id answers `404`.

### Notes

- The API base URL from Flutter web code must be `http://localhost:8000` —
  the JS runs in your host browser, so compose service names don't resolve.
- CORS for `http://localhost:5050` is configured in
  `packages/backend/config/cors.php` via `FRONTEND_URL` in `.env`.
- SQLite database lives at `packages/backend/database/database.sqlite`
  (bind-mounted, survives `docker compose down`). Migrations run on API start.
