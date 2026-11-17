import { API_URL } from './env';
import { mailCursor, readOtp } from './mail';

export function uniqueEmail(tag: string): string {
  const rand = Math.random().toString(36).slice(2, 8);
  return `e2e+${tag}-${Date.now()}-${rand}@flowfi.test`.toLowerCase();
}

async function request(method: string, token: string | null, path: string, body?: unknown) {
  const response = await fetch(`${API_URL}/api/v1${path}`, {
    method,
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await response.text();
  if (!response.ok) throw new Error(`${method} ${path} → ${response.status}: ${text}`);
  return text ? JSON.parse(text) : null;
}

export const api = {
  get: (token: string, path: string) => request('GET', token, path),
  post: (token: string | null, path: string, body?: unknown) => request('POST', token, path, body),
  patch: (token: string, path: string, body?: unknown) => request('PATCH', token, path, body),
  delete: (token: string, path: string) => request('DELETE', token, path),

  async signUp({ firstName, email = uniqueEmail('api') }: { firstName: string; email?: string }) {
    const since = mailCursor();
    await request('POST', null, '/auth/otp/request', { email });
    const code = await readOtp(email, since);
    const { user, token } = await request('POST', null, '/auth/otp/verify', { email, code });
    await request('PATCH', token, `/users/${user.id}`, { first_name: firstName });
    return { email, token: token as string, userId: user.id as number };
  },
};
