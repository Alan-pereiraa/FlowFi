# FlowFi end-to-end tests

Playwright drives the Flutter web build against a throwaway Laravel API. Each test is recorded on video. Nothing here changes the app: the run uses its own SQLite file, its own storage folder and its own ports.

| Piece | Where |
|---|---|
| API | `php -S 127.0.0.1:8100` with Laravel's router script, env from `support/env.ts` |
| Web app | `python3 -m http.server 5100` serving `.tmp/web` |
| Database | `.tmp/db.sqlite`, recreated and migrated before every run |
| Laravel storage (log, compiled views) | `.tmp/storage` (via `LARAVEL_STORAGE_PATH`) |
| OTP mails | `.tmp/storage/logs/laravel.log` (mailer `log`), or Mailpit with `E2E_MAIL=mailpit` |

## Prerequisites

- PHP 8.3 and `composer install` in `packages/backend`. No `.env` is needed; if one exists, the variables in `support/env.ts` take precedence.
- Flutter, for the web build.
- Node 22, then in this folder: `npm install` and `npx playwright install chromium`.
- Python 3, to serve the web build.

## Run

```sh
cd e2e
npm run build:web     # once, and again after every frontend change (slow: minutes)
npm test              # all specs, headless, one worker
npm run test:auth     # one spec group
npm run test:headed   # watch the browser
npx playwright test specs/auth.spec.ts -g "wrong code"   # one test
E2E_WORKERS=2 npm test                                   # more workers
npm run report        # open the HTML report
```

- Videos: `recordings/<test>/video.webm`, one for every test, whether it passed or failed. Failed tests also keep a screenshot and a trace.
- HTML report: `playwright-report/`, with the videos embedded.
- Both folders are wiped at the start of each run.
- If something already listens on 8100 or 5100, Playwright reuses it.
- `ledger:send-reminders` and `ledger:generate-recurring` do not run on a schedule here. Call `artisan('ledger:send-reminders')` from a spec.

### Mailpit instead of the log

```sh
E2E_MAIL=mailpit npm test    # Mailpit on 127.0.0.1:1025 (SMTP) and :8025 (API); override with E2E_MAILPIT_URL
```

## Helpers (`support/`)

```ts
// ui.ts
openApp(page, path = '/'): Promise<void>          // goto /#<path>, then enableSemantics
enableSemantics(page): Promise<void>              // call again after page.reload()
fillField(locator, value): Promise<void>          // click, then fill (Flutter needs focus first)
signInThroughUi(page, { firstName?, email? }): Promise<{ email }>

// api.ts
uniqueEmail(tag): string                          // e2e+<tag>-<ms>-<rand>@flowfi.test
api.signUp({ firstName, email? }): Promise<{ email, token, userId }>
api.get(token, path) / api.post(token | null, path, body?) / api.patch(token, path, body?) / api.delete(token, path)

// mail.ts
mailCursor(): number                              // take it before the request that sends the code
readOtp(email, since, timeoutMs = 15000): Promise<string>

// env.ts
artisan(command): string                          // php artisan <command> with the e2e env, returns stdout
```

- `signInThroughUi` opens `/login`, sends the code, reads it and clicks "Entrar".
  - New user and `firstName` given: completes the profile and returns to the dashboard.
  - User already signed up with `api.signUp`: the profile is complete, so it goes straight to the dashboard.
  - With `firstName`, it ends by asserting "Olá, {firstName}". Without it, it returns as soon as the URL is `/complete-profile` or `/dashboard`.
- API paths are relative to `/api/v1`, for example `api.post(token, '/categories', {...})`.
- Seed through `api`, then sign in through the UI with the same email.

## Locator conventions

- Use the exact strings from the Dart source. Copy them; don't retype accents.
- Prefer `page.getByRole('button', { name })`, then `getByLabel`, then `getByText`. Add `exact: true` when a name is a prefix of another, as with "Entrar".
- Don't use CSS on Flutter internals. The only exception is `flt-semantics-placeholder`, which is handled in `enableSemantics`.
- Text fields: `AppTextField` draws its `label` as a separate `Text` above the input, so the input's accessible name does not come from it. Pick inputs by position on the screen, `page.getByRole('textbox').nth(i)`, and fill them with `fillField`.
- Routes are hash URLs: `/#/dashboard`. Assert with `expect(page).toHaveURL(/#\/dashboard/)`.
- Use a fresh user per test (`uniqueEmail`, `api.signUp`). Never rely on another test's data.

## First run checklist

This scaffold was written and type-checked, but it has never run end to end. On the first run, check these in order:

1. **Env passthrough.** `curl http://127.0.0.1:8100/up` answers 200, and after one login `.tmp/storage/logs/laravel.log` exists. If the log is in `packages/backend/storage/logs` instead, `php -S` is not passing env vars to Laravel.
   - Confirmed so far: `artisan` CLI honours `LARAVEL_STORAGE_PATH` and the other variables.
   - The earlier spike also saw `php -S` write compiled views to its own storage folder.
2. **CORS.** `FRONTEND_URL=http://127.0.0.1:5100` must match the page origin, or every API call from the browser fails as a network error ("Sem conexão…").
3. **Semantics placeholder.** `enableSemantics` waits up to 60 s for `flt-semantics-placeholder`, then clicks it through `evaluate` because it is hidden. If the tree never appears, run `npm run test:headed` and inspect the page.
4. **Input order and names.** Check that `getByRole('textbox')` returns Email first and the code second on `/login`, and Nome first on the profile form. If Flutter names inputs after their hint text (for example "Insira seu código temporário"), switch to names; they are steadier than positions.
5. **OTP log format.** Checked against a mail rendered with the real log mailer: the code is inside `<strong …>` in the HTML part. If `readOtp` times out, read the log and adjust `CODE` in `support/mail.ts`.
6. **Button names.** The avatar button's name is its tooltip "Perfil", plus perhaps the initials. "Enviar Código" changes to "Reenviar em Ns" after a send.
7. **Throttles.** `CACHE_STORE=array` lives for one request, so the OTP limits (3/min per email) never trigger. If you see 429s, the env is not reaching the server (see 1).
