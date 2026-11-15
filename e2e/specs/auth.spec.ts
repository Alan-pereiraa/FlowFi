import { expect, test } from '@playwright/test';
import { api, uniqueEmail } from '../support/api';
import { mailCursor, readOtp } from '../support/mail';
import { enableSemantics, fillField, openApp, signInThroughUi } from '../support/ui';

test('a new user logs in, completes the profile and lands on the dashboard', async ({ page }) => {
  await signInThroughUi(page, { firstName: 'Ana' });
  await expect(page).toHaveURL(/#\/dashboard/);
});

test('reloading the page keeps the user signed in', async ({ page }) => {
  const { email } = await api.signUp({ firstName: 'Bia' });
  await signInThroughUi(page, { email, firstName: 'Bia' });

  await page.reload();
  await enableSemantics(page);
  await expect(page.getByText('Olá, Bia')).toBeVisible();
  await expect(page).toHaveURL(/#\/dashboard/);
});

test('"Sair da conta" on the profile page returns to login', async ({ page }) => {
  const { email } = await api.signUp({ firstName: 'Caio' });
  await signInThroughUi(page, { email, firstName: 'Caio' });

  await page.getByRole('button', { name: 'Perfil' }).click();
  await expect(page.getByText('Editar Perfil').first()).toBeVisible();
  await page.getByRole('button', { name: 'Sair da conta' }).click();

  await expect(page.getByText('Bem-Vindo!')).toBeVisible();
  await expect(page).toHaveURL(/#\/login/);
});

test('a wrong code shows the error message', async ({ page }) => {
  const email = uniqueEmail('wrong-code');
  await openApp(page, '/login');

  await fillField(page.getByRole('textbox').nth(0), email);
  const since = mailCursor();
  await page.getByRole('button', { name: 'Enviar Código' }).click();
  await expect(page.getByText('Enviamos um código para o seu e-mail.')).toBeVisible();
  const code = await readOtp(email, since);
  const wrong = String((Number(code) + 1) % 1_000_000).padStart(6, '0');

  await fillField(page.getByRole('textbox').nth(1), wrong);
  await page.getByRole('button', { name: 'Entrar', exact: true }).click();

  await expect(page.getByText('O código é inválido ou expirou.')).toBeVisible();
  await expect(page).toHaveURL(/#\/login/);
});

test('editing the profile name updates the greeting', async ({ page }) => {
  const { email } = await api.signUp({ firstName: 'Davi' });
  await signInThroughUi(page, { email, firstName: 'Davi' });

  await page.getByRole('button', { name: 'Perfil' }).click();
  await expect(page.getByText('Editar Perfil').first()).toBeVisible();
  await fillField(page.getByRole('textbox').nth(0), 'Duda');
  await page.getByRole('button', { name: 'Atualizar Perfil' }).click();

  await expect(page.getByText('Perfil Atualizado Com Sucesso!')).toBeVisible();
  await page.getByRole('button', { name: 'Voltar Para Tela Principal' }).click();
  await expect(page.getByText('Olá, Duda')).toBeVisible();
});
