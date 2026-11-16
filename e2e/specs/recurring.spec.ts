import { expect, test, type Page } from '@playwright/test';
import { api } from '../support/api';
import { artisan } from '../support/env';
import { fillField, signInThroughUi, tap } from '../support/ui';

const MONTHS = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'];

function todayIso(): string {
  return new Date().toLocaleDateString('en-CA', { timeZone: 'America/Sao_Paulo' });
}

// Carbon's addMonthsNoOverflow (PeriodCalculator::occurrenceDate): Jan 31 + 1 month = Feb 28/29.
function addMonths(iso: string, months: number): string {
  const [y, m, d] = iso.split('-').map(Number);
  const first = new Date(Date.UTC(y, m - 1 + months, 1));
  const lastDay = new Date(Date.UTC(first.getUTCFullYear(), first.getUTCMonth() + 1, 0)).getUTCDate();
  first.setUTCDate(Math.min(d, lastDay));
  return first.toISOString().slice(0, 10);
}

// Dates.input: dd/mm/aaaa.
function br(iso: string): string {
  const [y, m, d] = iso.split('-');
  return `${d}/${m}/${y}`;
}

// Dates.dayHeader + TransactionsPage._capitalizeMonth: "Hoje, 15 de Novembro", "15 de Setembro de 2025".
function dayHeader(iso: string): string {
  const [y, m, d] = iso.split('-').map(Number);
  const today = todayIso();
  let label = `${d} de ${MONTHS[m - 1]}`;
  if (y !== Number(today.slice(0, 4))) label = `${label} de ${y}`;
  if (iso === today) return `Hoje, ${label}`;
  const yesterday = new Date(Date.parse(today) - 86_400_000).toISOString().slice(0, 10);
  return iso === yesterday ? `Ontem, ${label}` : label;
}

async function seedRecurring(token: string, body: Record<string, unknown>) {
  const { data } = await api.post(token, '/recurring-transactions', { type: 'income', period_unit: 'month', ...body });
  return data;
}

async function transactionsOf(token: string, recurringId: number) {
  const { data } = await api.get(token, '/transactions?per_page=100');
  return (data as { recurring_transaction_id: number | null }[]).filter((t) => t.recurring_transaction_id === recurringId);
}

async function openTransactions(page: Page) {
  await tap(page.getByRole('tab', { name: 'Transações' }));
  await expect(page).toHaveURL(/#\/transactions$/);
}

// The recurrence card is a ListTile in MergeSemantics: one switch whose name is title + subtitle.
const recurrenceSwitch = (page: Page, subtitle: RegExp = /./) =>
  page.getByRole('switch', { name: new RegExp(`Transação Recorrente[\\s\\S]*${subtitle.source}`) });

test('a recurring income repeated 3 times shows "1 de 3 vezes" and the next date', async ({ page }) => {
  const { email, token } = await api.signUp({ firstName: 'Rita' });
  await signInThroughUi(page, { email, firstName: 'Rita' });

  await openTransactions(page);
  await tap(page.getByRole('button', { name: 'Nova transação' }));
  await expect(page).toHaveURL(/#\/transactions\/new/);

  await tap(page.getByRole('button', { name: 'Entrada', exact: true }));
  // Inputs on the form, in order: amount, Descrição, Data (read-only).
  await fillField(page.getByRole('textbox').nth(0), '150000');
  await fillField(page.getByRole('textbox').nth(1), 'Salario mensal');
  await tap(recurrenceSwitch(page, /Repetir mais vezes/));

  // "Repetir / Um número de vezes" is selected by default with 2x; pick 3x.
  await tap(page.getByRole('button', { name: /Quantas vezes repetir/ }));
  await tap(page.getByRole('menuitem', { name: '3x', exact: true }));
  await tap(page.getByRole('button', { name: 'Salvar Transação' }));

  await expect(page).toHaveURL(/#\/transactions$/);
  const tile = page.getByRole('button', { name: /Salario mensal/ });
  await expect(tile).toHaveCount(1);
  await expect(tile).toHaveAccessibleName(/\+ R\$\s1\.500,00/);

  await tap(tile);
  await expect(page).toHaveURL(/#\/transactions\/\d+\/edit/);
  const next = br(addMonths(todayIso(), 1));
  const card = recurrenceSwitch(page, new RegExp(`Repete todo mês, 1 de 3 vezes\\.\\s+Próxima: ${next}`));
  await expect(card).toBeVisible();
  await expect(card).toBeChecked();

  const { data } = await api.get(token, '/recurring-transactions');
  expect(data).toHaveLength(1);
  expect(data[0]).toMatchObject({ type: 'income', occurrences: 3, generated_count: 1, start_date: todayIso() });
});

test('a recurrence that started two months ago backfills the past months', async ({ page }) => {
  const { email, token } = await api.signUp({ firstName: 'Saulo' });
  const start = addMonths(todayIso(), -2);
  const dates = [0, 1, 2].map((n) => addMonths(start, n));
  // The form's date picker would work too, but driving Material's calendar is brittle; seed instead.
  const recurring = await seedRecurring(token, {
    description: 'Aluguel recebido',
    amount: '800.00',
    start_date: start,
    occurrences: 4,
  });
  expect(recurring.generated_count).toBe(3);
  expect(recurring.next_occurrence_on).toBe(addMonths(start, 3));

  await signInThroughUi(page, { email, firstName: 'Saulo' });
  await openTransactions(page);
  const tiles = page.getByRole('button', { name: /Aluguel recebido/ });
  // "Este Mês" is on by default and hides the older ones.
  await expect(tiles).toHaveCount(1);

  await tap(page.getByRole('checkbox', { name: 'Este Mês' }));
  await expect(tiles).toHaveCount(3);
  for (const date of dates) {
    await expect(page.getByText(dayHeader(date), { exact: true })).toBeVisible();
  }
});

test('ending a recurrence from a generated transaction shows "Encerrada"', async ({ page }) => {
  const { email, token } = await api.signUp({ firstName: 'Tiago' });
  const today = todayIso();
  const recurring = await seedRecurring(token, { description: 'Mesada', amount: '200.00', start_date: today });

  await signInThroughUi(page, { email, firstName: 'Tiago' });
  await openTransactions(page);
  await tap(page.getByRole('button', { name: /Mesada/ }));
  await expect(page).toHaveURL(/#\/transactions\/\d+\/edit/);

  const active = recurrenceSwitch(
    page,
    new RegExp(`Repete todo mês, sem data para terminar\\.\\s+Próxima: ${br(addMonths(today, 1))}`),
  );
  await expect(active).toBeChecked();
  await tap(active);

  await expect(page.getByText('Cancelar transação recorrente?')).toBeVisible();
  await tap(page.getByRole('button', { name: 'Cancelar recorrência', exact: true }));
  await expect(page.getByText('Recorrência cancelada.')).toBeVisible();
  await expect(page).toHaveURL(/#\/transactions$/);

  await tap(page.getByRole('button', { name: /Mesada/ }));
  const ended = recurrenceSwitch(page, /Encerrada\. Repetia todo mês\./);
  await expect(ended).toBeVisible();
  await expect(ended).not.toBeChecked();

  const { data } = await api.get(token, `/recurring-transactions/${recurring.id}`);
  expect(data).toMatchObject({ next_occurrence_on: null, end_date: today });
});

test('ledger:generate-recurring never creates a duplicate occurrence', async () => {
  const { token } = await api.signUp({ firstName: 'Uba' });
  const start = addMonths(todayIso(), -1);
  const recurring = await seedRecurring(token, { description: 'Rendimento', amount: '50.00', start_date: start });
  expect(await transactionsOf(token, recurring.id)).toHaveLength(2);

  // Simulate a run that inserted the second occurrence but crashed before advancing the schedule:
  // that date is due again although its transaction already exists.
  artisan(
    `tinker --execute='\\App\\Domains\\Ledger\\Models\\RecurringTransaction::whereKey(${recurring.id})` +
      `->update(["next_occurrence_on" => "${addMonths(start, 1)}", "generated_count" => 1]);'`,
  );

  for (let run = 0; run < 2; run++) {
    artisan('ledger:generate-recurring');
    expect(await transactionsOf(token, recurring.id)).toHaveLength(2);
    const { data } = await api.get(token, `/recurring-transactions/${recurring.id}`);
    expect(data).toMatchObject({ generated_count: 2, next_occurrence_on: addMonths(start, 2) });
  }
});
