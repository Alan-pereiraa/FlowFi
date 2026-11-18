import { expect, test, type Page } from '@playwright/test';
import { api } from '../support/api';
import { enableSemantics, fillField, shown, signInThroughUi, tap } from '../support/ui';

const limitField = (page: Page) => page.getByRole('textbox').nth(0);
const nameField = (page: Page) => page.getByRole('textbox').nth(1);

const categoryCard = (page: Page, label: string) => page.getByRole('group', { name: label, exact: true });

const today = () => new Date().toLocaleDateString('en-CA', { timeZone: 'America/Sao_Paulo' });

async function openCategories(page: Page) {
  await tap(page.getByRole('tab', { name: 'Categorias' }));
  await expect(page).toHaveURL(/#\/categories/);
  await expect(page.getByText('Organize seus gastos e defina limites mensais.')).toBeVisible();
}

async function seedUser(firstName: string) {
  const user = await api.signUp({ firstName });
  return { ...user, firstName };
}

async function seedCategory(token: string, body: { name: string; limit_amount?: number | null }) {
  const { data } = await api.post(token, '/categories', { icon: 'local_offer', color: '#00530C', type: 'expense', ...body });
  return data as { id: number };
}

test('a new user sees the empty state', async ({ page }) => {
  const { email, firstName } = await seedUser('Elis');
  await signInThroughUi(page, { email, firstName });
  await openCategories(page);

  await expect(page.getByText('Nenhuma categoria ainda')).toBeVisible();
  await expect(page.getByText('Organize seus gastos e defina um limite mensal.')).toBeVisible();
});

test('creates a category with an icon, a colour and a limit set with the stepper', async ({ page }) => {
  const { email, token, firstName } = await seedUser('Fabi');
  await signInThroughUi(page, { email, firstName });
  await openCategories(page);

  await tap(page.getByRole('button', { name: 'Nova Categoria' }));
  await expect(page).toHaveURL(/#\/categories\/new/);
  await expect(page.getByText('Adicionar Categoria')).toBeVisible();
  await expect(page.getByText('Deixe em 00,00 para não definir um limite.')).toBeVisible();

  await tap(page.getByRole('button', { name: 'Aumentar limite' }));
  await tap(page.getByRole('button', { name: 'Aumentar limite' }));
  await tap(limitField(page));
  await expect(limitField(page)).toHaveValue('100,00');

  await fillField(nameField(page), 'Mercado');

  await tap(page.getByRole('button', { name: 'Escolher ícone' }));
  await expect(page.getByText('Escolha um ícone')).toBeVisible();
  await tap(page.getByRole('button', { name: 'Ícone shopping cart' }));
  await expect(page.getByText('Escolha um ícone')).toBeHidden();

  await tap(page.getByRole('button', { name: 'Escolher cor' }));
  await expect(page.getByText('Escolha uma cor')).toBeVisible();
  await tap(page.getByRole('button', { name: 'Cor', exact: true }).nth(5));
  await expect(page.getByText('Escolha uma cor')).toBeHidden();

  await tap(page.getByRole('button', { name: 'Salvar' }));

  await expect(shown(page, 'Categoria criada.')).toBeVisible();
  await expect(page).toHaveURL(/#\/categories$/);
  await expect(categoryCard(page, 'Mercado R$ 0,00 / R$ 100,00 0%')).toBeVisible();

  const { data } = await api.get(token, '/categories');
  expect(data).toEqual([
    expect.objectContaining({ name: 'Mercado', icon: 'shopping_cart', color: '#42A5F5' }),
  ]);
});

test('creates a category without a limit', async ({ page }) => {
  const { email, firstName } = await seedUser('Gabi');
  await signInThroughUi(page, { email, firstName });
  await openCategories(page);

  await tap(page.getByRole('button', { name: 'Nova Categoria' }));
  await fillField(nameField(page), 'Assinaturas');
  await tap(page.getByRole('button', { name: 'Salvar' }));

  await expect(shown(page, 'Categoria criada.')).toBeVisible();
  await expect(categoryCard(page, 'Assinaturas R$ 0,00 / Sem limite --')).toBeVisible();
});

test('a duplicate name shows the backend error', async ({ page }) => {
  const { email, token, firstName } = await seedUser('Hugo');
  await seedCategory(token, { name: 'Mercado' });
  await signInThroughUi(page, { email, firstName });
  await openCategories(page);

  await tap(page.getByRole('button', { name: 'Nova Categoria' }));
  await fillField(nameField(page), 'mercado');
  await tap(page.getByRole('button', { name: 'Salvar' }));

  await expect(page.getByText('Já existe uma categoria com esse nome.')).toBeVisible();
  await expect(page).toHaveURL(/#\/categories\/new/);
});

test('editing the name and limit updates the card', async ({ page }) => {
  const { email, token, firstName } = await seedUser('Iara');
  const { id } = await seedCategory(token, { name: 'Cinema', limit_amount: 200 });
  await signInThroughUi(page, { email, firstName });
  await openCategories(page);
  await expect(categoryCard(page, 'Cinema R$ 0,00 / R$ 200,00 0%')).toBeVisible();

  await tap(page.getByRole('button', { name: 'Editar', exact: true }));
  await expect(page).toHaveURL(new RegExp(`#/categories/${id}/edit`));
  await expect(page.getByText('Editar Categoria')).toBeVisible();
  await tap(nameField(page));
  await expect(nameField(page)).toHaveValue('Cinema');
  await tap(limitField(page));
  await expect(limitField(page)).toHaveValue('200,00');

  await fillField(nameField(page), 'Streaming');
  await fillField(limitField(page), '35000', '350,00');
  await tap(page.getByRole('button', { name: 'Salvar' }));

  await expect(shown(page, 'Categoria atualizada.')).toBeVisible();
  await expect(page).toHaveURL(/#\/categories$/);
  await expect(categoryCard(page, 'Streaming R$ 0,00 / R$ 350,00 0%')).toBeVisible();
  await expect(shown(page, 'Cinema')).toBeHidden();
});

test('removing a category after the confirm dialog removes its card', async ({ page }) => {
  const { email, token, firstName } = await seedUser('Joca');
  await seedCategory(token, { name: 'Academia' });
  await signInThroughUi(page, { email, firstName });
  await openCategories(page);

  await tap(page.getByRole('button', { name: 'Editar', exact: true }));
  await tap(page.getByRole('button', { name: 'Remover', exact: true }));
  await expect(page.getByText('Remover categoria?')).toBeVisible();
  await expect(page.getByText(/as transações dela ficam sem categoria/)).toBeVisible();
  await tap(page.getByRole('button', { name: 'Remover', exact: true }).last());

  await expect(shown(page, 'Categoria removida.')).toBeVisible();
  await expect(page).toHaveURL(/#\/categories$/);
  await expect(page.getByText('Nenhuma categoria ainda')).toBeVisible();
  await expect(shown(page, 'Academia')).toBeHidden();
});

test("a card shows this month's spend, the percent and the limit warnings", async ({ page }) => {
  const { email, token, firstName } = await seedUser('Kika');
  const near = await seedCategory(token, { name: 'Restaurantes', limit_amount: 1000 });
  const over = await seedCategory(token, { name: 'Viagens', limit_amount: 1000 });
  for (const [category, amount] of [[near, 850], [over, 150]] as const) {
    await api.post(token, '/transactions', {
      type: 'expense',
      category_id: category.id,
      date: today(),
      total_amount: amount,
      description: 'Gasto e2e',
    });
  }
  await api.patch(token, `/categories/${over.id}`, { limit_amount: 100 });
  await signInThroughUi(page, { email, firstName });
  await openCategories(page);

  await expect(categoryCard(page, 'Restaurantes R$ 850,00 / R$ 1.000,00 85% Próximo do limite')).toBeVisible();
  await expect(categoryCard(page, 'Viagens R$ 150,00 / R$ 100,00 150% Limite estourado em R$ 50,00')).toBeVisible();
});

test('reloading the edit page loads the category by id', async ({ page }) => {
  const { email, token, firstName } = await seedUser('Lia');
  const { id } = await seedCategory(token, { name: 'Farmácia', limit_amount: 1500 });
  await signInThroughUi(page, { email, firstName });
  await openCategories(page);
  await tap(page.getByRole('button', { name: 'Editar', exact: true }));
  await expect(page).toHaveURL(new RegExp(`#/categories/${id}/edit`));

  await page.reload();
  await enableSemantics(page);

  await expect(page).toHaveURL(new RegExp(`#/categories/${id}/edit`));
  await expect(page.getByText('Editar Categoria')).toBeVisible();
  await tap(nameField(page));
  await expect(nameField(page)).toHaveValue('Farmácia');
  await tap(limitField(page));
  await expect(limitField(page)).toHaveValue('1.500,00');
  await expect(page.getByRole('button', { name: 'Remover', exact: true })).toBeVisible();
});

test.fixme('the edit form shows the saved category, not the copy from the list', async ({ page }) => {
  const { email, token, firstName } = await seedUser('Malu');
  const { id } = await seedCategory(token, { name: 'Padaria' });
  await signInThroughUi(page, { email, firstName });
  await openCategories(page);
  await expect(categoryCard(page, 'Padaria R$ 0,00 / Sem limite --')).toBeVisible();

  await api.patch(token, `/categories/${id}`, { name: 'Confeitaria' });
  await tap(page.getByRole('button', { name: 'Editar', exact: true }));

  await tap(nameField(page));
  await expect(nameField(page)).toHaveValue('Confeitaria');
});
