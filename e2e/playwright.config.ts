import path from 'node:path';
import { defineConfig } from '@playwright/test';
import { API_URL, BACKEND_DIR, STORAGE_DIRS, WEB_URL, apiEnv } from './support/env';

const router = '../vendor/laravel/framework/src/Illuminate/Foundation/resources/server.php';
// Off by default: a server left running from an earlier run may carry an old env.
const reuseExistingServer = process.env.E2E_REUSE_SERVERS === '1';

export default defineConfig({
  testDir: './specs',
  outputDir: 'recordings',
  globalSetup: './global-setup.ts',
  fullyParallel: false,
  workers: Number(process.env.E2E_WORKERS ?? 1),
  retries: 0,
  timeout: 120_000,
  expect: { timeout: 15_000 },
  reporter: [['list'], ['html', { outputFolder: 'playwright-report', open: 'never' }]],
  use: {
    baseURL: WEB_URL,
    video: { mode: 'on', size: { width: 1280, height: 800 } },
    screenshot: 'only-on-failure',
    trace: 'retain-on-failure',
    viewport: { width: 1280, height: 800 },
    locale: 'pt-BR',
    timezoneId: 'America/Sao_Paulo',
    // Granting nothing: Playwright auto-denies prompts (never blocks) and the app skips FCM registration.
    permissions: [],
  },
  projects: [{ name: 'chromium', use: { browserName: 'chromium' } }],
  webServer: [
    {
      // Laravel's router script reads getcwd() as the public dir, so run from public/ like artisan serve.
      // Laravel reads LARAVEL_STORAGE_PATH from $_ENV, which php.ini's default variables_order (GPCS) leaves empty.
      command:
        'test -f ../vendor/autoload.php || { echo "Missing vendor/: run composer install in packages/backend" >&2; exit 1; }; ' +
        `mkdir -p ${STORAGE_DIRS.map((d) => `"${d}"`).join(' ')} && php -d variables_order=EGPCS -S 127.0.0.1:8100 ${router}`,
      cwd: path.join(BACKEND_DIR, 'public'),
      env: apiEnv,
      url: `${API_URL}/up`,
      reuseExistingServer,
      timeout: 60_000,
    },
    {
      command:
        'test -f .tmp/web/index.html || { echo "Missing .tmp/web: run npm run build:web" >&2; exit 1; }; ' +
        'python3 -m http.server 5100 --bind 127.0.0.1 --directory .tmp/web',
      cwd: __dirname,
      url: WEB_URL,
      reuseExistingServer,
      timeout: 60_000,
    },
  ],
});
