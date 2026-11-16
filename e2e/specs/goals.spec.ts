import { expect, test, type Page } from '@playwright/test';
import { api } from '../support/api';
import { enableSemantics, fillField, signInThroughUi, tap } from '../support/ui';

// Detail page at 1280 px is two columns: deposit and withdraw on the left, edit on the right.
const DEPOSIT = 0;
const WITHDRAW = 1;
const EDIT_NAME = 2;

const MONTHS = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];

// The backend checks balances against today in America/Sao_Paulo.
const today = () => new Date().toLocaleDateString('en-CA', { timeZone: 'America/Sao_Paulo' });

// DateLabels.monthYear: "Nov 2026".
const monthYear = (ymd: string) => `${MONTHS[Number(ymd.slice(5, 7)) - 1]} ${ymd.slice(0, 4)}`;

async function seedGoal(token: string, name: string, target: number): Promise<number> {
  const { data } = await api.post(token, '/goals', {
    name,
    icon: 'savings',
    color: '#00530C',
    target_amount: target,
  });
  return data.id;
}

const seedIncome = (token: string, amount: number) =>
  api.post(token, '/transactions', { type: 'income', total_amount: amount, date: today() });

const seedDeposit = (token: string, goalId: number, amount: number) =>
  api.post(token, '/transactions', {
    type: 'transfer',
    goal_id: goalId,
    total_amount: amount,
    date: today(),
    description: 'Depósito na meta',
  });

async function openGoals(page: Page): Promise<void> {
  await tap(page.getByRole('tab', { name: 'Metas' }));
  await expect(page.getByText('Minhas Metas', { exact: true })).toBeVisible();
}

// GoalCard excludes its children from semantics; its name is "<name>. <saved> de <target>. …".
const goalCard = (page: Page, name: string) => page.getByRole('button', { name: new RegExp(`^${name}\\.`) });

async function openGoal(page: Page, name: string): Promise<void> {
  await openGoals(page);
  await tap(goalCard(page, name));
  await expect(page.getByText('Editar meta')).toBeVisible();
}

async function signUpAndSignIn(page: Page, firstName: string) {
  const user = await api.signUp({ firstName });
  await signInThroughUi(page, { email: user.email, firstName });
  return user;
}

test('a new user sees the empty goals state', async ({ page }) => {
  await signUpAndSignIn(page, 'Gabi');
  await openGoals(page);

  await expect(page.getByText('Nenhuma meta ainda')).toBeVisible();
  await expect(page.getByText('Defina um novo objetivo para seu futuro financeiro.')).toBeVisible();
});

test('creating an open-ended goal with a custom appearance shows it as "Contínuo"', async ({ page }) => {
  const { token } = await signUpAndSignIn(page, 'Gael');
  await openGoals(page);

  await tap(page.getByRole('button', { name: 'Criar Nova Meta' }));
  await expect(page.getByText('Nova Meta', { exact: true })).toBeVisible();

  await fillField(page.getByRole('textbox').nth(0), 'Viagem');
  await tap(page.getByRole('button', { name: 'Escolher ícone e cor' }));
  await expect(page.getByText('Aparência')).toBeVisible();
  await tap(page.getByRole('button', { name: 'Ícone flight', exact: true }));
  // Swatches are all named "Cor"; index 5 is #42A5F5 in AppPalette.hexes.
  await tap(page.getByRole('button', { name: 'Cor', exact: true }).nth(5));
  await tap(page.getByRole('button', { name: 'Concluir' }));

  const target = page.getByRole('textbox').nth(1);
  await fillField(target, '120000');
  await expect(target).toHaveValue('1.200,00');
  await tap(page.getByRole('button', { name: 'Criar Meta', exact: true }));

  await expect(page.getByText('Meta criada com sucesso!')).toBeVisible();
  await expect(page).toHaveURL(/#\/goals\/success/);
  // The summary Card has no button or field, so its texts merge into one DOM text: never use exact here.
  await expect(page.getByText('Viagem')).toBeVisible();
  await expect(page.getByText('Contínua')).toBeVisible();
  await expect(page.getByText('R$ 1.200,00').first()).toBeVisible();
  await expect(page.getByText('Contribuição Mensal')).toHaveCount(0);

  const { data: goals } = await api.get(token, '/goals');
  expect(goals).toHaveLength(1);
  expect(goals[0]).toMatchObject({ name: 'Viagem', icon: 'flight', color: '#42A5F5', expires_at: null });

  await tap(page.getByText('Ver minhas metas'));
  await expect(page).toHaveURL(/#\/goals$/);
  // The "Contínuo" pill is inside GoalCard's excluded semantics; the card's label says "Meta contínua." instead.
  await expect(goalCard(page, 'Viagem')).toHaveAccessibleName(
    'Viagem. R$ 0,00 de R$ 1.200,00. 0% concluído. Meta contínua.',
  );
});

test('creating a goal with a target date shows the monthly contribution', async ({ page }) => {
  await signUpAndSignIn(page, 'Hugo');
  await openGoals(page);
  await tap(page.getByRole('button', { name: 'Criar Nova Meta' }));

  await fillField(page.getByRole('textbox').nth(0), 'Carro');
  await fillField(page.getByRole('textbox').nth(1), '500000');

  // The picker opens on today, already selected: accepting it avoids naming calendar cells.
  await tap(page.getByRole('textbox').nth(2));
  await tap(page.getByRole('button', { name: 'OK', exact: true }));
  await tap(page.getByRole('button', { name: 'Criar Meta', exact: true }));

  await expect(page.getByText('Meta criada com sucesso!')).toBeVisible();
  await expect(page.getByText('Contribuição Mensal')).toBeVisible();
  await expect(page.getByText(monthYear(today()))).toBeVisible();
  await expect(page.getByText('Contínua')).toHaveCount(0);
});

test('"Adicionar valor" saves the amount and updates the progress', async ({ page }) => {
  const { email, token } = await api.signUp({ firstName: 'Iris' });
  await seedGoal(token, 'Reserva', 1000);
  await seedIncome(token, 500);
  await signInThroughUi(page, { email, firstName: 'Iris' });
  await openGoal(page, 'Reserva');

  const amount = page.getByRole('textbox').nth(DEPOSIT);
  await fillField(amount, '25000');
  await expect(amount).toHaveValue('250,00');
  await tap(page.getByRole('button', { name: 'Adicionar valor' }));

  await expect(page.getByText('Valor adicionado.')).toBeVisible();
  await expect(page.getByText('R$ 250,00 / R$ 1.000,00')).toBeVisible();
  await expect(page.getByText('25%')).toBeVisible();
  await expect(page.getByText('R$ 750,00')).toBeVisible();
  await expect(page.getByText('O valor volta para o seu saldo. Disponível na meta: R$ 250,00.')).toBeVisible();
});

test('"Resgatar valor" rejects more than the balance, then withdraws a valid amount', async ({ page }) => {
  const { email, token } = await api.signUp({ firstName: 'Joao' });
  const goalId = await seedGoal(token, 'Ferias', 1000);
  await seedIncome(token, 500);
  await seedDeposit(token, goalId, 200);
  await signInThroughUi(page, { email, firstName: 'Joao' });
  await openGoal(page, 'Ferias');

  const amount = page.getByRole('textbox').nth(WITHDRAW);
  await fillField(amount, '30000');
  await tap(page.getByRole('button', { name: 'Resgatar valor' }));
  await expect(page.getByText('O resgate não pode ser maior que R$ 200,00.')).toBeVisible();

  await fillField(amount, '5000');
  await expect(amount).toHaveValue('50,00');
  await tap(page.getByRole('button', { name: 'Resgatar valor' }));

  await expect(page.getByText('Valor resgatado.')).toBeVisible();
  await expect(page.getByText('R$ 150,00 / R$ 1.000,00')).toBeVisible();
  await expect(page.getByText('O valor volta para o seu saldo. Disponível na meta: R$ 150,00.')).toBeVisible();
});

test('a goal with a balance cannot be deleted until it is withdrawn', async ({ page }) => {
  const { email, token } = await api.signUp({ firstName: 'Kai' });
  const goalId = await seedGoal(token, 'Moto', 1000);
  await seedIncome(token, 500);
  await seedDeposit(token, goalId, 100);
  await signInThroughUi(page, { email, firstName: 'Kai' });
  await openGoal(page, 'Moto');

  await tap(page.getByRole('button', { name: 'Excluir meta' }));
  await expect(page.getByText('Resgate o saldo primeiro')).toBeVisible();
  await expect(page.getByText(/Esta meta ainda tem R\$ 100,00 guardados\./)).toBeVisible();
  await tap(page.getByRole('button', { name: 'Entendi' }));
  await expect(page.getByText('Resgate o saldo primeiro')).toHaveCount(0);
  await expect(page).toHaveURL(new RegExp(`#/goals/${goalId}$`));
  expect((await api.get(token, `/goals/${goalId}`)).data.id).toBe(goalId);

  await fillField(page.getByRole('textbox').nth(WITHDRAW), '10000');
  await tap(page.getByRole('button', { name: 'Resgatar valor' }));
  await expect(page.getByText('Valor resgatado.')).toBeVisible();
  await expect(page.getByText('Não há valor guardado nesta meta para resgatar.')).toBeVisible();

  await tap(page.getByRole('button', { name: 'Excluir meta' }));
  await expect(page.getByText('Excluir meta?')).toBeVisible();
  await tap(page.getByRole('button', { name: 'Excluir', exact: true }));

  await expect(page.getByText('Meta excluída.')).toBeVisible();
  await expect(page.getByText('Nenhuma meta ainda')).toBeVisible();
  await expect(api.get(token, `/goals/${goalId}`)).rejects.toThrow(/→ 404/);
});

test('"Salvar alterações" renames the goal and closes the page', async ({ page }) => {
  const { email, token } = await api.signUp({ firstName: 'Lia' });
  await seedGoal(token, 'Casa', 1000);
  await signInThroughUi(page, { email, firstName: 'Lia' });
  await openGoal(page, 'Casa');

  await fillField(page.getByRole('textbox').nth(EDIT_NAME), 'Casa nova');
  await tap(page.getByRole('button', { name: 'Salvar alterações' }));

  // Current behavior: saving pops back to the list instead of staying on the detail.
  await expect(page.getByText('Meta atualizada.')).toBeVisible();
  await expect(page).toHaveURL(/#\/goals$/);
  await expect(goalCard(page, 'Casa nova')).toBeVisible();
});

test('a deposit without income shows the insufficient-balance error', async ({ page }) => {
  const { email, token } = await api.signUp({ firstName: 'Malu' });
  await seedGoal(token, 'Estudos', 1000);
  await signInThroughUi(page, { email, firstName: 'Malu' });
  await openGoal(page, 'Estudos');

  await fillField(page.getByRole('textbox').nth(DEPOSIT), '1000');
  await tap(page.getByRole('button', { name: 'Adicionar valor' }));

  await expect(page.getByText('Saldo insuficiente para fazer esta transferência.')).toBeVisible();
  await expect(page.getByText('Valor adicionado.')).toHaveCount(0);
  await expect(page.getByText('R$ 0,00 / R$ 1.000,00')).toBeVisible();
});

test('reloading /goals/:id loads the goal from the API', async ({ page }) => {
  const { email, token } = await api.signUp({ firstName: 'Nina' });
  const goalId = await seedGoal(token, 'Bicicleta', 1000);
  await signInThroughUi(page, { email, firstName: 'Nina' });
  await openGoal(page, 'Bicicleta');

  await page.reload();
  await enableSemantics(page);

  await expect(page).toHaveURL(new RegExp(`#/goals/${goalId}$`));
  await expect(page.getByText('Editar meta')).toBeVisible();
  await expect(page.getByText('Bicicleta')).toBeVisible();
  await expect(page.getByText('R$ 0,00 / R$ 1.000,00')).toBeVisible();
  // The engine writes the DOM value only while the field has focus.
  await tap(page.getByRole('textbox').nth(EDIT_NAME));
  await expect(page.getByRole('textbox').nth(EDIT_NAME)).toHaveValue('Bicicleta');
});
