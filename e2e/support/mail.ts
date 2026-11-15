import fs from 'node:fs';
import { LOG_FILE, MAILPIT_URL, USE_MAILPIT } from './env';

const CODE = /<strong[^>]*>\s*(\d{6})\s*<\/strong>/;
const LOG_ENTRY = /^\[\d{4}-\d{2}-\d{2}[ T][^\]]*\] /m;

// Take the cursor before the request that sends the code, then pass it to readOtp.
export function mailCursor(): number {
  if (USE_MAILPIT) return Date.now();
  return fs.existsSync(LOG_FILE) ? fs.statSync(LOG_FILE).size : 0;
}

export async function readOtp(email: string, since: number, timeoutMs = 15_000): Promise<string> {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const code = USE_MAILPIT ? await fromMailpit(email, since) : fromLog(email, since);
    if (code) return code;
    await new Promise((resolve) => setTimeout(resolve, 250));
  }
  throw new Error(`No OTP for ${email} after ${timeoutMs} ms (${USE_MAILPIT ? MAILPIT_URL : LOG_FILE})`);
}

function fromLog(email: string, offset: number): string | undefined {
  if (!fs.existsSync(LOG_FILE)) return undefined;
  const buffer = fs.readFileSync(LOG_FILE);
  const entries = buffer.subarray(Math.min(offset, buffer.length)).toString('utf8').split(LOG_ENTRY);
  return entries
    .reverse()
    .map((entry) => (entry.includes(email) ? entry.match(CODE)?.[1] : undefined))
    .find(Boolean);
}

async function fromMailpit(email: string, since: number): Promise<string | undefined> {
  const query = encodeURIComponent(`to:"${email}"`);
  const list = await fetch(`${MAILPIT_URL}/api/v1/search?query=${query}&limit=5`).then((r) => r.json());
  const latest = (list.messages ?? []).find((m: { Created: string }) => Date.parse(m.Created) >= since);
  if (!latest) return undefined;
  const message = await fetch(`${MAILPIT_URL}/api/v1/message/${latest.ID}`).then((r) => r.json());
  return (message.HTML ?? message.Text ?? '').match(CODE)?.[1];
}
