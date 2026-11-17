import { execSync } from 'node:child_process';
import path from 'node:path';

export const E2E_DIR = path.resolve(__dirname, '..');
export const TMP_DIR = path.join(E2E_DIR, '.tmp');
export const BACKEND_DIR = path.resolve(E2E_DIR, '../packages/backend');
export const STORAGE_DIR = path.join(TMP_DIR, 'storage');
export const DB_FILE = path.join(TMP_DIR, 'db.sqlite');
export const LOG_FILE = path.join(STORAGE_DIR, 'logs/laravel.log');

export const API_URL = 'http://127.0.0.1:8100';
export const WEB_URL = 'http://127.0.0.1:5100';
export const MAILPIT_URL = process.env.E2E_MAILPIT_URL ?? 'http://127.0.0.1:8025';
export const USE_MAILPIT = process.env.E2E_MAIL === 'mailpit';

export const STORAGE_DIRS = [
  'app/private',
  'framework/cache/data',
  'framework/sessions',
  'framework/views',
  'logs',
].map((dir) => path.join(STORAGE_DIR, dir));

// Real env vars win over packages/backend/.env, so the dev setup is never read or touched.
export const apiEnv: Record<string, string> = {
  APP_NAME: 'FlowFi',
  APP_ENV: 'local',
  APP_KEY: 'base64:Zmxvd2ZpLWUyZS1maXhlZC10ZXN0LWtleS0zMmJ5dGU=',
  APP_DEBUG: 'true',
  APP_URL: API_URL,
  FRONTEND_URL: WEB_URL,
  APP_CONFIG_CACHE: path.join(TMP_DIR, 'no-config-cache.php'),
  APP_ROUTES_CACHE: path.join(TMP_DIR, 'no-routes-cache.php'),
  APP_EVENTS_CACHE: path.join(TMP_DIR, 'no-events-cache.php'),
  // Laravel regenerates these two; keep them out of packages/backend/bootstrap/cache.
  APP_SERVICES_CACHE: path.join(TMP_DIR, 'services.php'),
  APP_PACKAGES_CACHE: path.join(TMP_DIR, 'packages.php'),
  LARAVEL_STORAGE_PATH: STORAGE_DIR,
  DB_CONNECTION: 'sqlite',
  DB_DATABASE: DB_FILE,
  CACHE_STORE: 'array',
  SESSION_DRIVER: 'array',
  QUEUE_CONNECTION: 'sync',
  LOG_CHANNEL: 'single',
  LOG_LEVEL: 'debug',
  MAIL_LOG_CHANNEL: 'single',
  MAIL_FROM_ADDRESS: 'no-reply@flowfi.test',
  MAIL_FROM_NAME: 'FlowFi',
  GEMINI_API_KEY: '',
  FIREBASE_CREDENTIALS: '',
  PHP_CLI_SERVER_WORKERS: '4',
  ...(USE_MAILPIT
    ? { MAIL_MAILER: 'smtp', MAIL_SCHEME: 'smtp', MAIL_HOST: '127.0.0.1', MAIL_PORT: '1025' }
    : { MAIL_MAILER: 'log' }),
};

export function artisan(command: string): string {
  return execSync(`php artisan ${command}`, {
    cwd: BACKEND_DIR,
    env: { ...process.env, ...apiEnv },
    encoding: 'utf8',
  });
}
