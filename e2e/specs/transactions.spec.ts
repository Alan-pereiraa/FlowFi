import { expect, test, type Locator, type Page } from '@playwright/test';
import { api } from '../support/api';
import { fillField, signInThroughUi } from '../support/ui';

// Form inputs, in widget order (transaction_form_page.dart): MoneyAmountField, then Descrição, then Data.
// VoiceFillCard, shown above them on create, has no text field.
const AMOUNT = 0;
const DESCRIPTION = 1;
const DATE = 2;

const TZ = 'America/Sao_Paulo';
const MONTHS = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];

// "YYYY-MM-DD" in São Paulo, shifted by whole days. The browser and the backend both use this zone.
function sp(offsetDays = 0): string {
  const [y, m, d] = new Date().toLocaleDateString('en-CA', { timeZone: TZ }).split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d + offsetDays)).toISOString().slice(0, 10);
}
const parts = (ymd: string) => ymd.split('-').map(Number);
// TransactionsPage day header for today: "Hoje, 15 de Novembro" (Dates.dayHeader + _capitalizeMonth).
const todayHeader = () => {
  const [, m, d] = parts(sp());
  const month = MONTHS[m - 1];
  return `Hoje, ${d} de ${month[0].toUpperCase()}${month.slice(1)}`;
};

const escape = (text: string) => text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

// A TransactionTile is a Card, so its texts merge into one node. With a "Pagar" button inside it
// becomes role=group named by aria-label; without one it is a plain button. Match either by its texts.
function row(page: Page, ...texts: string[]): Locator {
  const name = new RegExp(texts.map(escape).join('.*'));
  return page.getByRole('button', { name }).or(page.getByRole('group', { name }));
}

// Text merged into a parent node (MoneyAmountField's Semantics label, SnackBar) lands in aria-label,
// which getByText does not read. Leaf Text nodes keep it as DOM text.
const shows = (page: Page, text: string) => page.getByText(text).or(page.getByLabel(text)).first();

async function openTransactions(page: Page) {
  await page.getByRole('tab', { name: 'Transações' }).click();
  await expect(page).toHaveURL(/#\/transactions/);
  await expect(page.getByRole('button', { name: 'Nova transação' })).toBeVisible();
}

async function openNewForm(page: Page) {
  await page.getByRole('button', { name: 'Nova transação' }).click();
  await expect(page).toHaveURL(/#\/transactions\/new/);
  await expect(page.getByText('Nova Transação', { exact: true })).toBeVisible();
}

async function typeAmount(page: Page, digits: string, formatted: string) {
  const amount = page.getByRole('textbox').nth(AMOUNT);
  await fillField(amount, digits);
  await expect(amount).toHaveValue(formatted);
}

async function save(page: Page) {
  await page.getByRole('button', { name: 'Salvar Transação' }).click();
}

const turnOffThisMonth = (page: Page) => page.getByRole('checkbox', { name: 'Este Mês' }).click();

async function seedUser(page: Page, firstName: string) {
  const user = await api.signUp({ firstName });
  return { ...user, firstName, signIn: () => signInThroughUi(page, { email: user.email, firstName }) };
}

async function seedCategory(token: string, name: string, limit_amount: number | null = null) {
  const { data } = await api.post(token, '/categories', { name, icon: 'local_offer', color: '#00530C', limit_amount });
  return data.id as number;
}

async function seedGoal(token: string, name: string) {
  const { data } = await api.post(token, '/goals', { name, icon: 'savings', color: '#00530C', target_amount: 1000 });
  return data.id as number;
}

type Seeded = { id: number; installments: { id: number; step: number }[] };

async function seedTransaction(token: string, body: Record<string, unknown>): Promise<Seeded> {
  const { data } = await api.post(token, '/transactions', { date: sp(), ...body });
  return data;
}

const seedSplit = (token: string, description: string, total_amount: number) =>
  seedTransaction(token, {
    type: 'expense',
    description,
    total_amount,
    installments_count: 3,
    period_unit: 'month',
    period_interval: 1,
  });

test('creates an income and an expense with a category; both show under today', async ({ page }) => {
  const user = await seedUser(page, 'Lia');
  await seedCategory(user.token, 'Salário');
  await seedCategory(user.token, 'Mercado');
  await user.signIn();
  await openTransactions(page);
  await expect(page.getByText('Nenhuma transação', { exact: true })).toBeVisible();

  await openNewForm(page);
  await page.getByRole('button', { name: 'Entrada', exact: true }).click();
  await typeAmount(page, '150000', '1.500,00');
  await fillField(page.getByRole('textbox').nth(DESCRIPTION), 'Freela');
  await page.getByRole('checkbox', { name: 'Salário' }).click();
  await save(page);
  await expect(page).toHaveURL(/#\/transactions$/);

  await openNewForm(page);
  await page.getByRole('button', { name: 'Saída', exact: true }).click();
  await typeAmount(page, '5000', '50,00');
  await fillField(page.getByRole('textbox').nth(DESCRIPTION), 'Feira');
  await page.getByRole('checkbox', { name: 'Mercado' }).click();
  await save(page);
  await expect(page).toHaveURL(/#\/transactions$/);

  await expect(page.getByText(todayHeader())).toBeVisible();
  await expect(row(page, 'Freela', 'Entrada • Salário', '+ R$ 1.500,00')).toBeVisible();
  await expect(row(page, 'Feira', 'Saída • Mercado • Paga', '- R$ 50,00')).toBeVisible();
});

test('a 3x split expense lists 1/3 paid today and the next two pending', async ({ page }) => {
  const user = await seedUser(page, 'Rui');
  await user.signIn();
  await openTransactions(page);
  await openNewForm(page);

  await typeAmount(page, '9000', '90,00');
  await fillField(page.getByRole('textbox').nth(DESCRIPTION), 'Geladeira');
  await page.getByRole('button', { name: 'Transação Parcelada' }).click();
  await page.getByRole('button', { name: 'Número de parcelas' }).click();
  await page.getByRole('menuitem', { name: '3x', exact: true }).click();
  await expect(page.getByText('O valor total é dividido em 3 parcelas mensais.')).toBeVisible();

  const [y, m] = parts(sp());
  await expect(page.getByText('Primeira parcela', { exact: true })).toBeVisible();
  await expect(
    page.getByText(`A primeira parcela conta em ${MONTHS[m - 1]} de ${y} e já entra como paga.`),
  ).toBeVisible();
  await save(page);
  await expect(page).toHaveURL(/#\/transactions$/);

  await expect(page.getByText(todayHeader())).toBeVisible();
  await expect(row(page, 'Geladeira', '1/3 • Paga', '- R$ 30,00')).toBeVisible();
  // "Este Mês" hides the installments due in later months.
  await expect(row(page, 'Geladeira', '2/3')).toHaveCount(0);

  await turnOffThisMonth(page);
  await expect(row(page, 'Geladeira', '2/3 • Pendente', '- R$ 30,00')).toBeVisible();
  await expect(row(page, 'Geladeira', '3/3 • Pendente', '- R$ 30,00')).toBeVisible();
  await expect(row(page, 'Geladeira', '1/3 • Paga')).toBeVisible();
});

test('"Pagar" marks an installment paid and "Desfazer" turns it back to pending', async ({ page }) => {
  const user = await seedUser(page, 'Noa');
  await seedSplit(user.token, 'Sofá', 300);
  await user.signIn();
  await openTransactions(page);
  await turnOffThisMonth(page);

  const second = row(page, 'Sofá', '2/3 • Pendente');
  await expect(second).toBeVisible();
  await second.getByRole('button', { name: 'Pagar' }).click();

  await expect(shows(page, 'Parcela paga.')).toBeVisible();
  await expect(row(page, 'Sofá', '2/3 • Paga')).toBeVisible();
  await expect(row(page, 'Sofá', '3/3 • Pendente')).toBeVisible();

  await page.getByRole('button', { name: 'Desfazer' }).click();
  await expect(row(page, 'Sofá', '2/3 • Pendente')).toBeVisible();
  await expect(row(page, 'Sofá', '2/3 • Paga')).toHaveCount(0);
});

test('the type menu shows only "Entradas"', async ({ page }) => {
  const user = await seedUser(page, 'Bel');
  await seedTransaction(user.token, { type: 'income', description: 'Salário do mês', total_amount: 3000 });
  await seedTransaction(user.token, { type: 'expense', description: 'Padaria', total_amount: 20 });
  await user.signIn();
  await openTransactions(page);
  await expect(row(page, 'Padaria')).toBeVisible();

  await page.getByRole('checkbox', { name: 'Todos os Tipos' }).click();
  await page.getByRole('menuitem', { name: 'Entradas', exact: true }).click();

  await expect(page.getByRole('checkbox', { name: 'Entradas' })).toBeVisible();
  await expect(row(page, 'Salário do mês', '+ R$ 3.000,00')).toBeVisible();
  await expect(row(page, 'Padaria')).toHaveCount(0);
});

test('the category menu shows only that category', async ({ page }) => {
  const user = await seedUser(page, 'Caio');
  const mercado = await seedCategory(user.token, 'Mercado');
  const lazer = await seedCategory(user.token, 'Lazer');
  await seedTransaction(user.token, { type: 'expense', description: 'Hortifruti', total_amount: 40, category_id: mercado });
  await seedTransaction(user.token, { type: 'expense', description: 'Cinema', total_amount: 30, category_id: lazer });
  await user.signIn();
  await openTransactions(page);
  await expect(row(page, 'Cinema')).toBeVisible();

  await page.getByRole('checkbox', { name: 'Todas as Categorias' }).click();
  await page.getByRole('menuitem', { name: 'Mercado', exact: true }).click();

  await expect(row(page, 'Hortifruti', 'Saída • Mercado')).toBeVisible();
  await expect(row(page, 'Cinema')).toHaveCount(0);
});

test('"Vencidas" shows only past-due pending installments', async ({ page }) => {
  const user = await seedUser(page, 'Iris');
  // A past-dated expense is born paid; unpaying it leaves a pending installment before today.
  const late = await seedTransaction(user.token, {
    type: 'expense',
    description: 'Conta de luz',
    total_amount: 120,
    date: sp(-5),
  });
  await api.patch(user.token, `/transactions/${late.id}/installments/${late.installments[0].id}/unpay`);
  await seedTransaction(user.token, { type: 'expense', description: 'Café', total_amount: 8 });
  await user.signIn();
  await openTransactions(page);
  await expect(row(page, 'Café')).toBeVisible();

  await page.getByRole('checkbox', { name: 'Vencidas' }).click();

  await expect(row(page, 'Conta de luz', 'Vencida', '- R$ 120,00')).toBeVisible();
  await expect(row(page, 'Café')).toHaveCount(0);
  // Turning "Vencidas" on also turns "Este Mês" off (TransactionListController.toggleOverdueOnly).
  await expect(page.getByRole('checkbox', { name: 'Este Mês' })).not.toBeChecked();
});

test('search filters by description, ignoring accents', async ({ page }) => {
  const user = await seedUser(page, 'Davi');
  await seedTransaction(user.token, { type: 'expense', description: 'Açaí da praia', total_amount: 25 });
  await seedTransaction(user.token, { type: 'expense', description: 'Uber', total_amount: 18 });
  await user.signIn();
  await openTransactions(page);
  await expect(row(page, 'Uber')).toBeVisible();

  await page.getByRole('button', { name: 'Buscar' }).click();
  // The search field is the only text field on the list page.
  await fillField(page.getByRole('textbox').nth(0), 'acai');

  await expect(row(page, 'Açaí da praia')).toBeVisible();
  await expect(row(page, 'Uber')).toHaveCount(0);

  await page.getByRole('button', { name: 'Fechar busca' }).click();
  await expect(row(page, 'Uber')).toBeVisible();
});

test('edits a description from the row, then deletes the transaction after confirming', async ({ page }) => {
  const user = await seedUser(page, 'Gil');
  await seedTransaction(user.token, { type: 'income', description: 'Freela', total_amount: 200 });
  await user.signIn();
  await openTransactions(page);

  await row(page, 'Freela', '+ R$ 200,00').click();
  await expect(page).toHaveURL(/#\/transactions\/\d+\/edit/);
  await expect(page.getByText('Editar Transação')).toBeVisible();
  const description = page.getByRole('textbox').nth(DESCRIPTION);
  await expect(description).toHaveValue('Freela');
  await fillField(description, 'Freela do site');
  await save(page);

  await expect(page).toHaveURL(/#\/transactions$/);
  await expect(row(page, 'Freela do site', '+ R$ 200,00')).toBeVisible();

  await row(page, 'Freela do site').click();
  await expect(page.getByText('Editar Transação')).toBeVisible();
  await page.getByRole('button', { name: 'Excluir transação' }).click();
  await expect(shows(page, 'Excluir transação?')).toBeVisible();
  await expect(shows(page, 'A transação e todas as suas parcelas serão removidas.')).toBeVisible();
  await page.getByRole('button', { name: 'Excluir', exact: true }).click();

  await expect(page).toHaveURL(/#\/transactions$/);
  await expect(page.getByText('Nenhuma transação', { exact: true })).toBeVisible();
});

test('an expense above the category limit is blocked under the amount', async ({ page }) => {
  const user = await seedUser(page, 'Teo');
  await seedCategory(user.token, 'Lazer', 100);
  await user.signIn();
  await openTransactions(page);
  await openNewForm(page);

  await typeAmount(page, '15000', '150,00');
  await page.getByRole('checkbox', { name: 'Lazer' }).click();
  await save(page);

  const [y, m] = parts(sp());
  const month = `${String(m).padStart(2, '0')}/${y}`;
  await expect(shows(page, `Esta transação ultrapassa o limite da categoria em ${month}.`)).toBeVisible();
  await expect(page).toHaveURL(/#\/transactions\/new/);
});

test('a transfer to a goal with no income shows the insufficient-balance error', async ({ page }) => {
  const user = await seedUser(page, 'Ana');
  await seedGoal(user.token, 'Reserva');
  await user.signIn();
  await openTransactions(page);
  await openNewForm(page);

  await page.getByRole('button', { name: 'Transferência', exact: true }).click();
  await expect(page.getByText('Meta de destino', { exact: false }).first()).toBeVisible();
  // _GoalOption merges its texts: "Reserva 0% R$ 0,00 de R$ 1.000,00".
  await page.getByRole('button', { name: /^Reserva/ }).click();
  await typeAmount(page, '5000', '50,00');
  await save(page);

  await expect(shows(page, 'Saldo insuficiente para fazer esta transferência.')).toBeVisible();
  await expect(page).toHaveURL(/#\/transactions\/new/);
});

// The transaction form has no "Resgate" segment to pick (TransactionTypeToggle only renders it when the
// type is already withdrawal), so the withdrawal goes through the goal page. Its client check compares
// against the balance it loaded; spending the goal down through the API afterwards lets the request
// reach the backend, which answers with its own message.
test.describe('withdrawal', () => {
  // Below 860 px GoalDetailPage stacks its cards, so the inputs read deposit, withdraw, then the edit form.
  test.use({ viewport: { width: 800, height: 1000 } });
  const WITHDRAW = 1;

  test('a withdrawal greater than the goal balance shows the backend error', async ({ page }) => {
    const user = await seedUser(page, 'Leo');
    const goalId = await seedGoal(user.token, 'Viagem');
    await seedTransaction(user.token, { type: 'income', total_amount: 500 });
    await seedTransaction(user.token, { type: 'transfer', goal_id: goalId, total_amount: 100 });
    await user.signIn();

    await page.getByRole('tab', { name: 'Metas' }).click();
    // GoalCard's name is "<name>. <saved> de <target>. …".
    await page.getByRole('button', { name: /^Viagem\./ }).click();
    await expect(page.getByText('O valor volta para o seu saldo. Disponível na meta: R$ 100,00.')).toBeVisible();

    await seedTransaction(user.token, { type: 'withdrawal', goal_id: goalId, total_amount: 60 });

    const amount = page.getByRole('textbox').nth(WITHDRAW);
    await fillField(amount, '8000');
    await expect(amount).toHaveValue('80,00');
    await page.getByRole('button', { name: 'Resgatar valor' }).click();

    await expect(shows(page, 'O resgate não pode ser maior que o valor guardado na meta (R$ 40,00).')).toBeVisible();
  });
});

test.fixme(
  'editing only the date of a 3x expense resets an installment paid early to pending (TransactionService.php:257 replans on any date change)',
  async ({ page }) => {
    const user = await seedUser(page, 'Ivo');
    const split = await seedSplit(user.token, 'Notebook', 900);
    const third = split.installments.find((i) => i.step === 3)!;
    await api.patch(user.token, `/transactions/${split.id}/installments/${third.id}/pay`);
    await user.signIn();
    await openTransactions(page);

    await row(page, 'Notebook', '1/3').click();
    await expect(page.getByText('Editar Transação')).toBeVisible();
    await expect(page.getByText(/• Paga$/)).toHaveCount(2);

    // Move the date one day within the same month. Material day buttons are named "<day>, <full date>".
    const [, , d] = parts(sp());
    const newDay = d > 1 ? d - 1 : d + 1;
    await page.getByRole('textbox').nth(DATE).click();
    await page.getByRole('button', { name: new RegExp(`^${newDay},`) }).click();
    await page.getByRole('button', { name: 'OK', exact: true }).click();
    await save(page);
    await expect(page).toHaveURL(/#\/transactions$/);

    await turnOffThisMonth(page);
    // Expected: the installment paid early stays paid. Today it comes back as "Pendente".
    await expect(row(page, 'Notebook', '3/3 • Paga')).toBeVisible();
  },
);

test.fixme(
  'switching to Resgate after turning recurrence on still submits a recurrence and shows a general error (transaction_form_page.dart:114 keeps _recurring)',
  async ({ page }) => {
    // Not reachable through the UI today: the "Resgate" segment only renders when the type is already
    // withdrawal (transaction_type_toggle.dart:67), and voice drafts never return a withdrawal.
    // If a "Resgate" entry point is added, this is the path that breaks.
    const user = await seedUser(page, 'Bia');
    await seedGoal(user.token, 'Reserva');
    await seedTransaction(user.token, { type: 'income', total_amount: 500 });
    await user.signIn();
    await openTransactions(page);
    await openNewForm(page);

    await page.getByRole('switch', { name: /Transação Recorrente/ }).click();
    await page.getByRole('button', { name: 'Resgate', exact: true }).click();
    await expect(page.getByRole('switch', { name: /Transação Recorrente/ })).toHaveCount(0);
    await page.getByRole('button', { name: /^Reserva/ }).click();
    await typeAmount(page, '1000', '10,00');
    await save(page);

    // Expected: a plain withdrawal is saved. Today POST /recurring-transactions answers 422 type.in, and
    // "type" is not a mapped field, so the form shows it as a general error.
    await expect(
      shows(page, 'Escolha entrada, saída ou transferência. Resgates não podem ser recorrentes.'),
    ).toHaveCount(0);
    await expect(page).toHaveURL(/#\/transactions$/);
  },
);
