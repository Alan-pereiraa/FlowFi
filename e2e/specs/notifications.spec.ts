import { expect, test, type Page } from '@playwright/test';
import { api } from '../support/api';
import { artisan } from '../support/env';
import { shown, signInThroughUi, tap } from '../support/ui';

const CATEGORY_WARNING = 'Limite da categoria quase atingido';
const categoryWarning = (name: string) => `Você já usou 85% do limite da categoria "${name}". Restam R$ 15,00.`;

function spDate(offsetDays = 0): string {
  const today = new Intl.DateTimeFormat('en-CA', { timeZone: 'America/Sao_Paulo' }).format(new Date());
  const [y, m, d] = today.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d + offsetDays)).toISOString().slice(0, 10);
}
const br = (isoDate: string) => isoDate.split('-').reverse().join('/');

const bell = (page: Page) => page.getByRole('button', { name: /^Notificações/ });
const badge = (page: Page, count: number) => page.getByRole('button', { name: `Notificações, ${count} não lidas` });
const noBadge = (page: Page) => page.getByRole('button', { name: /não lidas/ });

const unreadCard = (page: Page, title: string, message: string) =>
  page.getByRole('button', { name: `Não lida. ${title}. ${message}`, exact: true });
const readCard = (page: Page, title: string, message: string) => shown(page, `${title}. ${message}`, true);

const chip = (page: Page, label: 'Todas' | 'Não lidas' | 'Lidas') =>
  page.getByRole('button', { name: label, exact: true }).or(page.getByRole('checkbox', { name: label, exact: true }));

async function seedCategoryWarning(token: string, name: string) {
  const { data: category } = await api.post(token, '/categories', {
    name,
    type: 'expense',
    icon: 'home',
    color: '#4CAF50',
    limit_amount: '100.00',
  });
  await api.post(token, '/transactions', {
    type: 'expense',
    category_id: category.id,
    date: spDate(),
    total_amount: '85.00',
  });
  return category.id as number;
}

async function openNotifications(page: Page) {
  await tap(bell(page));
  await expect(page).toHaveURL(/#\/notifications/);
  await expect(page.getByRole('heading', { name: 'Notificações' })).toBeVisible();
}

async function notificationsOf(token: string) {
  const { data, meta } = await api.get(token, '/notifications?per_page=100');
  return { items: data as { id: number; subject: string; message: string }[], total: meta.total as number };
}

test('a new user has no badge and an empty notifications page', async ({ page }) => {
  const { email } = await api.signUp({ firstName: 'Nina' });
  await signInThroughUi(page, { email, firstName: 'Nina' });

  await expect(bell(page)).toBeVisible();
  await expect(noBadge(page)).toHaveCount(0);

  await openNotifications(page);
  await expect(page.getByText('Nenhuma notificação')).toBeVisible();
  await expect(page.getByText('Avisos sobre limites, parcelas e metas aparecem aqui.')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Marcar todas como lidas' })).toBeDisabled();
});

test('spending 85% of a category limit shows the warning and a badge of 1', async ({ page }) => {
  const { email, token } = await api.signUp({ firstName: 'Otto' });
  await seedCategoryWarning(token, 'Mercado');

  await signInThroughUi(page, { email, firstName: 'Otto' });
  await expect(badge(page, 1)).toBeVisible();

  await openNotifications(page);
  await expect(unreadCard(page, CATEGORY_WARNING, categoryWarning('Mercado'))).toBeVisible();
});

test('a pending expense due tomorrow gets one "due soon" reminder, even when the job runs twice', async ({ page }) => {
  const { email, token } = await api.signUp({ firstName: 'Pia' });
  const due = spDate(1);
  await api.post(token, '/transactions', {
    type: 'expense',
    description: 'Conta de luz',
    date: due,
    total_amount: '120.00',
  });

  artisan('ledger:send-reminders');
  artisan('ledger:send-reminders');
  const { items } = await notificationsOf(token);
  expect(items.filter((n) => n.subject === 'installment_due_soon')).toHaveLength(1);

  await signInThroughUi(page, { email, firstName: 'Pia' });
  await expect(badge(page, 1)).toBeVisible();
  await openNotifications(page);
  await expect(
    unreadCard(page, 'Parcela vencendo em breve', `Gasto "Conta de luz" (R$ 120,00) vence em ${br(due)}.`),
  ).toHaveCount(1);
});

test('an unpaid past installment gets one "overdue" reminder', async ({ page }) => {
  const { email, token } = await api.signUp({ firstName: 'Rui' });
  const due = spDate(-3);
  const { data: transaction } = await api.post(token, '/transactions', {
    type: 'expense',
    description: 'Aluguel',
    date: due,
    total_amount: '50.00',
  });
  await api.patch(token, `/transactions/${transaction.id}/installments/${transaction.installments[0].id}/unpay`);

  artisan('ledger:send-reminders');
  artisan('ledger:send-reminders');
  const { items } = await notificationsOf(token);
  expect(items.filter((n) => n.subject === 'installment_overdue')).toHaveLength(1);

  await signInThroughUi(page, { email, firstName: 'Rui' });
  await openNotifications(page);
  await expect(
    unreadCard(page, 'Parcela em atraso', `Gasto "Aluguel" (R$ 50,00) venceu em ${br(due)} e ainda não foi paga.`),
  ).toHaveCount(1);
});

test('a goal expiring within 7 days gets a deadline reminder', async ({ page }) => {
  const { email, token } = await api.signUp({ firstName: 'Sol' });
  const expires = spDate(3);
  await api.post(token, '/goals', {
    name: 'Viagem',
    icon: 'savings',
    color: '#2196F3',
    target_amount: '1000.00',
    expires_at: expires,
  });

  artisan('ledger:send-reminders');

  await signInThroughUi(page, { email, firstName: 'Sol' });
  await expect(badge(page, 1)).toBeVisible();
  await openNotifications(page);
  await expect(
    unreadCard(
      page,
      'Prazo da meta se aproximando',
      `Sua meta "Viagem" termina em ${br(expires)} e tem R$ 0,00 de R$ 1.000,00 guardados.`,
    ),
  ).toBeVisible();
});

test('filters, tapping a card to mark it read, and "Marcar todas como lidas"', async ({ page }) => {
  const { email, token } = await api.signUp({ firstName: 'Teo' });
  await seedCategoryWarning(token, 'Mercado');
  await seedCategoryWarning(token, 'Lazer');

  await signInThroughUi(page, { email, firstName: 'Teo' });
  await expect(badge(page, 2)).toBeVisible();
  await openNotifications(page);

  const mercado = categoryWarning('Mercado');
  const lazer = categoryWarning('Lazer');
  await expect(unreadCard(page, CATEGORY_WARNING, mercado)).toBeVisible();
  await expect(unreadCard(page, CATEGORY_WARNING, lazer)).toBeVisible();

  await tap(unreadCard(page, CATEGORY_WARNING, mercado));
  await expect(readCard(page, CATEGORY_WARNING, mercado)).toBeVisible();
  await expect(unreadCard(page, CATEGORY_WARNING, mercado)).toHaveCount(0);

  await tap(chip(page, 'Não lidas'));
  await expect(unreadCard(page, CATEGORY_WARNING, lazer)).toBeVisible();
  await expect(readCard(page, CATEGORY_WARNING, mercado)).toHaveCount(0);

  await tap(chip(page, 'Lidas'));
  await expect(readCard(page, CATEGORY_WARNING, mercado)).toBeVisible();
  await expect(unreadCard(page, CATEGORY_WARNING, lazer)).toHaveCount(0);

  await tap(chip(page, 'Todas'));
  await tap(page.getByRole('button', { name: 'Marcar todas como lidas' }));
  await expect(readCard(page, CATEGORY_WARNING, lazer)).toBeVisible();
  await expect(readCard(page, CATEGORY_WARNING, mercado)).toBeVisible();

  await tap(chip(page, 'Não lidas'));
  await expect(page.getByText('Tudo em dia')).toBeVisible();
  await expect(page.getByText('Você não tem notificações não lidas.')).toBeVisible();

  await tap(page.getByRole('button', { name: 'Voltar' }));
  await expect(page).toHaveURL(/#\/dashboard/);
  await expect(bell(page)).toBeVisible();
  await expect(noBadge(page)).toHaveCount(0);
});

test('swiping a card left and confirming deletes it', async ({ page }) => {
  const { email, token } = await api.signUp({ firstName: 'Uma' });
  await seedCategoryWarning(token, 'Mercado');
  await api.patch(token, '/notifications/read');

  await signInThroughUi(page, { email, firstName: 'Uma' });
  await openNotifications(page);
  const card = readCard(page, CATEGORY_WARNING, categoryWarning('Mercado'));
  await expect(card).toBeVisible();

  const box = (await card.boundingBox())!;
  const y = box.y + box.height / 2;
  await page.mouse.move(box.x + box.width - 16, y);
  await page.mouse.down();
  await page.mouse.move(box.x + 16, y, { steps: 20 });
  await page.mouse.up();

  await expect(page.getByText('Excluir notificação?')).toBeVisible();
  await expect(page.getByText('Ela deixa de aparecer na sua lista.')).toBeVisible();
  await tap(page.getByRole('button', { name: 'Excluir', exact: true }));

  await expect(page.getByText('Nenhuma notificação')).toBeVisible();
  await expect.poll(async () => (await notificationsOf(token)).total).toBe(0);
});

test('a notification deleted through the API is gone from the list', async ({ page }) => {
  const { email, token } = await api.signUp({ firstName: 'Vera' });
  await seedCategoryWarning(token, 'Mercado');
  await seedCategoryWarning(token, 'Lazer');
  const { items } = await notificationsOf(token);
  const mercado = items.find((n) => n.message === categoryWarning('Mercado'))!;
  await api.delete(token, `/notifications/${mercado.id}`);

  await signInThroughUi(page, { email, firstName: 'Vera' });
  await expect(badge(page, 1)).toBeVisible();
  await openNotifications(page);
  await expect(unreadCard(page, CATEGORY_WARNING, categoryWarning('Lazer'))).toBeVisible();
  await expect(unreadCard(page, CATEGORY_WARNING, categoryWarning('Mercado'))).toHaveCount(0);
});

test.fixme('the badge does not refresh when a notification is created while the user stays on the dashboard', async ({
  page,
}) => {
  const { email, token } = await api.signUp({ firstName: 'Wil' });
  await signInThroughUi(page, { email, firstName: 'Wil' });
  await expect(noBadge(page)).toHaveCount(0);

  await seedCategoryWarning(token, 'Mercado');

  await expect(badge(page, 1)).toBeVisible({ timeout: 30_000 });
});

test.fixme('tapping a card does not open its subject', async ({ page }) => {
  const { email, token } = await api.signUp({ firstName: 'Xavi' });
  await seedCategoryWarning(token, 'Mercado');

  await signInThroughUi(page, { email, firstName: 'Xavi' });
  await openNotifications(page);
  await tap(unreadCard(page, CATEGORY_WARNING, categoryWarning('Mercado')));

  await expect(page).toHaveURL(/#\/categories/);
});
