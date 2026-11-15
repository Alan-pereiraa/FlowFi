import { expect, test, type Page } from '@playwright/test';
import { api } from '../support/api';
import { enableSemantics, fillField, shown, signInThroughUi } from '../support/ui';

function todayIso(): string {
  return new Date().toLocaleDateString('en-CA', { timeZone: 'America/Sao_Paulo' });
}

// money_flow / Money.format: "R$ 1.500,00".
function brl(cents: number): string {
  const units = Math.floor(cents / 100).toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.');
  return `R$ ${units},${String(cents % 100).padStart(2, '0')}`;
}

// MonthSummaryCard's label, with MonthSummary.incomeUsedPercent (no transfers or withdrawals here).
function summaryLabel(incomeCents: number, expenseCents: number): string {
  const left = incomeCents - expenseCents;
  const usage =
    incomeCents <= 0
      ? 'Sem entradas no mês'
      : `${expenseCents <= 0 ? 0 : Math.floor((expenseCents * 100) / incomeCents)}% de uso`;
  const remaining = left < 0 ? `${brl(-left)} acima das entradas` : `${brl(left)} restantes`;
  return `Total gasto no mês: ${brl(expenseCents)}. Valor total de entradas: ${brl(incomeCents)}. ${usage}. ${remaining}.`;
}

async function seedTransaction(token: string, body: Record<string, unknown>) {
  const { data } = await api.post(token, '/transactions', { date: todayIso(), ...body });
  return data;
}

async function reloadDashboard(page: Page) {
  await page.reload();
  await enableSemantics(page);
  await expect(page).toHaveURL(/#\/dashboard$/);
}

test('a new user sees zeros, then the month totals once income and an expense exist', async ({ page }) => {
  const { email, token } = await api.signUp({ firstName: 'Vera' });
  await signInThroughUi(page, { email, firstName: 'Vera' });

  await expect(shown(page, summaryLabel(0, 0), true)).toBeVisible();
  expect(summaryLabel(0, 0)).toContain('Sem entradas no mês. R$ 0,00 restantes.');
  await expect(shown(page, 'Entradas do mês: R$ 0,00', true)).toBeVisible();
  await expect(shown(page, 'Saídas do mês: R$ 0,00', true)).toBeVisible();
  await expect(shown(page, 'Você ainda não tem metas.')).toBeVisible();
  await expect(shown(page, 'Nenhuma transação registrada.')).toBeVisible();

  await seedTransaction(token, { type: 'income', total_amount: '1500.00', description: 'Salario' });
  await seedTransaction(token, { type: 'expense', total_amount: '400.00', description: 'Mercado' });
  await reloadDashboard(page);

  // 400 of 1500 is 26.67%: the card floors it to 26.
  expect(summaryLabel(150_000, 40_000)).toContain('26% de uso. R$ 1.100,00 restantes.');
  await expect(shown(page, summaryLabel(150_000, 40_000), true)).toBeVisible();
  await expect(shown(page, 'Entradas do mês: R$ 1.500,00', true)).toBeVisible();
  await expect(shown(page, 'Saídas do mês: R$ 400,00', true)).toBeVisible();
});

test('"Últimas Transações" shows the 3 newest and "Ver todas" opens the list', async ({ page }) => {
  const { email, token } = await api.signUp({ firstName: 'Wagner' });
  // Same date, so the backend orders them by id: Compra 4, 3, 2.
  for (const n of [1, 2, 3, 4]) {
    await seedTransaction(token, { type: 'expense', total_amount: `${n}0.00`, description: `Compra ${n}` });
  }
  await signInThroughUi(page, { email, firstName: 'Wagner' });

  await expect(shown(page, /Compra 4[\s\S]*Compra 3[\s\S]*Compra 2/)).toBeVisible();
  await expect(shown(page, 'Compra 1')).toHaveCount(0);

  // Two "Ver todas": Metas Recentes comes first, then Últimas Transações (dashboard_page.dart:156-177).
  await page.getByRole('button', { name: 'Ver todas', exact: true }).nth(1).click();
  await expect(page).toHaveURL(/#\/transactions$/);
});

test('"Metas Recentes" shows the 2 newest goals and opens the one tapped', async ({ page }) => {
  const { email, token } = await api.signUp({ firstName: 'Xena' });
  const goals = [];
  for (const name of ['Viagem', 'Carro', 'Reserva']) {
    const { data } = await api.post(token, '/goals', { name, icon: 'savings', color: '#1E88E5', target_amount: '1000.00' });
    goals.push(data);
  }
  await signInThroughUi(page, { email, firstName: 'Xena' });

  const row = (name: string) => page.getByRole('button', { name: `${name}. R$ 0,00 de R$ 1.000,00. 0% concluído.` });
  await expect(row('Reserva')).toBeVisible();
  await expect(row('Carro')).toBeVisible();
  await expect(row('Viagem')).toHaveCount(0);

  await row('Reserva').click();
  await expect(page).toHaveURL(new RegExp(`#/goals/${goals[2].id}$`));
  await expect(page.getByRole('button', { name: 'Minhas metas' })).toBeVisible();
  await expect(page.getByText('Editar meta', { exact: true })).toBeVisible();
});

test('the "+" button opens the form, and saving returns to updated totals', async ({ page }) => {
  await signInThroughUi(page, { firstName: 'Yuri' });
  await expect(shown(page, 'Entradas do mês: R$ 0,00', true)).toBeVisible();

  await page.getByRole('button', { name: 'Nova transação' }).click();
  await expect(page).toHaveURL(/#\/dashboard\/new-transaction/);
  await expect(page.getByText('Nova Transação', { exact: true })).toBeVisible();

  await page.getByRole('button', { name: 'Entrada', exact: true }).click();
  // Inputs on the form, in order: amount, Descrição, Data (read-only).
  await fillField(page.getByRole('textbox').nth(0), '50000');
  await fillField(page.getByRole('textbox').nth(1), 'Freela');
  await page.getByRole('button', { name: 'Salvar Transação' }).click();

  await expect(page).toHaveURL(/#\/dashboard$/);
  await expect(shown(page, 'Entradas do mês: R$ 500,00', true)).toBeVisible();
  await expect(shown(page, summaryLabel(50_000, 0), true)).toBeVisible();
  await expect(shown(page, 'Freela')).toBeVisible();
});

test('the tab bar moves between all four tabs', async ({ page }) => {
  await signInThroughUi(page, { firstName: 'Zeca' });

  await page.getByRole('tab', { name: 'Transações' }).click();
  await expect(page).toHaveURL(/#\/transactions$/);
  await expect(shown(page, 'Toque em + para registrar a primeira.')).toBeVisible();

  await page.getByRole('tab', { name: 'Metas' }).click();
  await expect(page).toHaveURL(/#\/goals$/);
  await expect(shown(page, 'Acompanhe seus objetivos financeiros e celebre o progresso.')).toBeVisible();

  await page.getByRole('tab', { name: 'Categorias' }).click();
  await expect(page).toHaveURL(/#\/categories$/);
  await expect(shown(page, 'Organize seus gastos e defina limites mensais.')).toBeVisible();

  await page.getByRole('tab', { name: 'Dashboard' }).click();
  await expect(page).toHaveURL(/#\/dashboard$/);
  await expect(page.getByText('Olá, Zeca')).toBeVisible();
});

test('an installment paid early counts in this month\'s SAÍDAS (#32)', async ({ page }) => {
  const { email, token } = await api.signUp({ firstName: 'Alice' });
  // 2x of R$ 100,00: the first is due today and born paid, the second is due next month.
  const expense = await seedTransaction(token, {
    type: 'expense',
    total_amount: '200.00',
    description: 'Celular',
    installments_count: 2,
    period_unit: 'month',
    period_interval: 1,
  });
  const second = expense.installments.find((i: { step: number }) => i.step === 2);
  expect(second.status).toBe('pending');

  await signInThroughUi(page, { email, firstName: 'Alice' });
  await expect(shown(page, 'Saídas do mês: R$ 100,00', true)).toBeVisible();

  await api.patch(token, `/transactions/${expense.id}/installments/${second.id}/pay`);
  await reloadDashboard(page);
  await expect(shown(page, 'Saídas do mês: R$ 200,00', true)).toBeVisible();
  await expect(shown(page, summaryLabel(0, 20_000), true)).toBeVisible();
});

test.fixme(
  'the "Este Mês" list hides an installment paid early this month, although the dashboard counts it',
  async ({ page }) => {
    // Since #32 the dashboard counts a paid installment by paid_at, but the list still filters
    // "Este Mês" by due date (transaction_list_state.dart:78, EloquentTransactionRepository.php:158).
    const { email, token } = await api.signUp({ firstName: 'Bruno' });
    const expense = await seedTransaction(token, {
      type: 'expense',
      total_amount: '200.00',
      description: 'Notebook',
      installments_count: 2,
      period_unit: 'month',
      period_interval: 1,
    });
    const second = expense.installments.find((i: { step: number }) => i.step === 2);
    await api.patch(token, `/transactions/${expense.id}/installments/${second.id}/pay`);

    await signInThroughUi(page, { email, firstName: 'Bruno' });
    await expect(shown(page, 'Saídas do mês: R$ 200,00', true)).toBeVisible();
    await page.getByRole('tab', { name: 'Transações' }).click();
    await expect(page.getByRole('button', { name: /Notebook[\s\S]*2\/2/ })).toBeVisible();
  },
);
