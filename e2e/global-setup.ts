import fs from 'node:fs';
import path from 'node:path';
import { BACKEND_DIR, DB_FILE, LOG_FILE, STORAGE_DIRS, apiEnv, artisan } from './support/env';

export default function globalSetup() {
  if (fs.existsSync(path.join(BACKEND_DIR, 'bootstrap/cache/config.php'))) {
    console.warn('bootstrap/cache/config.php exists; e2e ignores it through APP_CONFIG_CACHE.');
  }

  for (const dir of STORAGE_DIRS) fs.mkdirSync(dir, { recursive: true });
  fs.rmSync(LOG_FILE, { force: true });
  // A stale package manifest outlives a composer update; Laravel rebuilds it on the next boot.
  fs.rmSync(apiEnv.APP_PACKAGES_CACHE, { force: true });
  for (const suffix of ['', '-journal', '-wal', '-shm']) fs.rmSync(DB_FILE + suffix, { force: true });
  fs.writeFileSync(DB_FILE, '');
  artisan('migrate --force');
}
