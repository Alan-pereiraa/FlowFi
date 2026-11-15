import fs from 'node:fs';
import path from 'node:path';
import { BACKEND_DIR, DB_FILE, LOG_FILE, STORAGE_DIRS, artisan } from './support/env';

export default function globalSetup() {
  if (!fs.existsSync(path.join(BACKEND_DIR, 'vendor/autoload.php'))) {
    throw new Error(`Run "composer install" in ${BACKEND_DIR} first.`);
  }
  if (fs.existsSync(path.join(BACKEND_DIR, 'bootstrap/cache/config.php'))) {
    console.warn('bootstrap/cache/config.php exists; e2e ignores it through APP_CONFIG_CACHE.');
  }

  for (const dir of STORAGE_DIRS) fs.mkdirSync(dir, { recursive: true });
  fs.rmSync(LOG_FILE, { force: true });
  fs.rmSync(DB_FILE, { force: true });
  fs.writeFileSync(DB_FILE, '');
  artisan('migrate --force');
}
