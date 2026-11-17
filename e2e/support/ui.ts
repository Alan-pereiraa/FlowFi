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
// Scoped to the semantics tree because a SnackBar's text is also copied into an aria-live element.
export function shown(page: Page, text: string | RegExp, exact = false): Locator {
  const tree = page.locator('flt-semantics-host');
  return tree.getByText(text, { exact }).or(tree.getByLabel(text, { exact })).first();
}

// A route pushed inside the app shell leaves an empty full-screen semantics node on top. It fails
// Playwright's hit-target check, yet Flutter still routes the pointer by position, as for a real
// user. So wait until the target stops moving (route transitions), then click through it.
export async function tap(target: Locator): Promise<void> {
  let last = '';
  await expect
    .poll(async () => {
      const box = JSON.stringify(await target.boundingBox());
      const settled = box === last && box !== 'null';
      last = box;
      return settled;
    }, { intervals: [100] })
    .toBe(true);
  await target.click({ force: true });
}

// Flutter only wires the <input> to its text field a moment after it gets focus. A fill sent before
// that lands in the DOM, then the engine resets it to the empty model value: retry until it sticks.
// shownAs is the text a formatter turns value into, e.g. money digits '35000' → '350,00'.
export async function fillField(field: Locator, value: string, shownAs = value): Promise<void> {
  await expect(async () => {
    await tap(field);
    await expect(field).toBeFocused({ timeout: 2_000 });
    await field.fill(value);
    await field.page().waitForTimeout(300);
    await expect(field).toHaveValue(shownAs, { timeout: 1 });
  }).toPass({ timeout: 15_000 });
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
  await tap(page.getByRole('button', { name: 'Enviar Código' }));
  await expect(shown(page, 'Enviamos um código para o seu e-mail.')).toBeVisible();

  await fillField(page.getByRole('textbox').nth(1), await readOtp(email, since));
  await tap(page.getByRole('button', { name: 'Entrar', exact: true }));
  // Hash routes never fire a load event, so waitForURL would hang.
  await expect(page).toHaveURL(/#\/(complete-profile|dashboard)/);

  if (!firstName) return { email };

  if (new URL(page.url()).hash.startsWith('#/complete-profile')) {
    await expect(page.getByText('Como podemos te chamar?')).toBeVisible();
    await fillField(page.getByRole('textbox').nth(0), firstName);
    await tap(page.getByRole('button', { name: 'Continuar' }));
    await expect(page.getByText('Perfil Atualizado Com Sucesso!')).toBeVisible();
    await tap(page.getByRole('button', { name: 'Voltar Para Tela Principal' }));
  }

  await expect(page.getByText(`Olá, ${firstName}`)).toBeVisible();
  return { email };
}
