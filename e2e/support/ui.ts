import { expect, type Locator, type Page } from '@playwright/test';
import { uniqueEmail } from './api';
import { mailCursor, readOtp } from './mail';

// Flutter web builds its accessibility tree only after the hidden placeholder is clicked.
// Call it again after every page.reload().
export async function enableSemantics(page: Page): Promise<void> {
  const placeholder = page.locator('flt-semantics-placeholder');
  await placeholder.waitFor({ state: 'attached', timeout: 60_000 });
  await placeholder.evaluate((el: HTMLElement) => el.click());
  await page.locator('flt-semantics').first().waitFor({ state: 'attached' });
}

// The app uses Flutter's default hash URLs: openApp(page, '/login') loads /#/login.
export async function openApp(page: Page, path = '/'): Promise<void> {
  await page.goto(path === '/' ? '/' : `/#${path}`);
  await enableSemantics(page);
}

// Text merged into a node that has child nodes (a Card holding a button or field, a SnackBar with an
// action) lands in aria-label, which getByText does not read. Leaf nodes keep it as DOM text.
export function shown(page: Page, text: string | RegExp, exact = false): Locator {
  return page.getByText(text, { exact }).or(page.getByLabel(text, { exact })).first();
}

// Flutter only wires the <input> to its text field once it has focus.
export async function fillField(field: Locator, value: string): Promise<void> {
  await field.click();
  await field.fill(value);
}

export async function signInThroughUi(
  page: Page,
  { firstName, email = uniqueEmail('ui') }: { firstName?: string; email?: string } = {},
): Promise<{ email: string }> {
  await openApp(page, '/login');
  await expect(shown(page, 'Bem-Vindo!')).toBeVisible();

  // AppTextField's label is a sibling Text, not the input's accessible name: pick inputs by position.
  await fillField(page.getByRole('textbox').nth(0), email);
  const since = mailCursor();
  await page.getByRole('button', { name: 'Enviar Código' }).click();
  await expect(shown(page, 'Enviamos um código para o seu e-mail.')).toBeVisible();

  await fillField(page.getByRole('textbox').nth(1), await readOtp(email, since));
  await page.getByRole('button', { name: 'Entrar', exact: true }).click();
  await page.waitForURL((url) => /^#\/(complete-profile|dashboard)/.test(url.hash));

  if (!firstName) return { email };

  if (new URL(page.url()).hash.startsWith('#/complete-profile')) {
    await expect(page.getByText('Como podemos te chamar?')).toBeVisible();
    await fillField(page.getByRole('textbox').nth(0), firstName);
    await page.getByRole('button', { name: 'Continuar' }).click();
    await expect(page.getByText('Perfil Atualizado Com Sucesso!')).toBeVisible();
    await page.getByRole('button', { name: 'Voltar Para Tela Principal' }).click();
  }

  await expect(page.getByText(`Olá, ${firstName}`)).toBeVisible();
  return { email };
}
