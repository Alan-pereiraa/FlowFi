import { expect, test, type Page } from '@playwright/test';
import { api } from '../support/api';
import { enableSemantics, fillField, signInThroughUi } from '../support/ui';

// Category form inputs, in widget order: the limit field (LimitStepper), then the name (CategoryNameField).
const limitField = (page: Page) => page.getByRole('textbox').nth(0);
const nameField = (page: Page) => page.getByRole('textbox').nth(1);

// The device month and the backend month agree because the config pins the browser to America/Sao_Paulo.
const today = () => new Date().toLocaleDateString('en-CA', { timeZone: 'America/Sao_Paulo' });

async function openCategories(page: Page) {
  await page.getByRole('tab', { name: 'Categorias' }).click();
  await expect(page).toHaveURL(/#\/categories/);
  await expect(page.getByText('Organize seus gastos e defina limites mensais.')).toBeVisible();
}

async function seedUser(firstName: string) {
  const user = await api.signUp({ firstName });
  return { ...user, firstName };
}

async function seedCategory(token: string, body: { name: string; limit_amount?: number | null }) {
  const { data } = await api.post(token, '/categories', { icon: 'local_offer', color: '#00530C', ...body });
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

  await page.getByRole('button', { name: 'Nova Categoria' }).click();
  await expect(page).toHaveURL(/#\/categories\/new/);
  await expect(page.getByText('Adicionar Categoria')).toBeVisible();
  await expect(page.getByText('Deixe em 00,00 para não definir um limite.')).toBeVisible();

  await page.getByRole('button', { name: 'Aumentar limite' }).click();
  await page.getByRole('button', { name: 'Aumentar limite' }).click();
  await expect(limitField(page)).toHaveValue('100,00');

  await fillField(nameField(page), 'Mercado');

  await page.getByRole('button', { name: 'Escolher ícone' }).click();
  await expect(page.getByText('Escolha um ícone')).toBeVisible();
  await page.getByRole('button', { name: 'Ícone shopping cart' }).click();
  await expect(page.getByText('Escolha um ícone')).toBeHidden();

  await page.getByRole('button', { name: 'Escolher cor' }).click();
  await expect(page.getByText('Escolha uma cor')).toBeVisible();
  // Swatches are all named "Cor", in AppPalette.hexes order: index 5 is #42A5F5.
  await page.getByRole('button', { name: 'Cor', exact: true }).nth(5).click();
  await expect(page.getByText('Escolha uma cor')).toBeHidden();

  await page.getByRole('button', { name: 'Salvar' }).click();

  await expect(page.getByText('Categoria criada.')).toBeVisible();
  await expect(page).toHaveURL(/#\/categories$/);
  await expect(page.getByText('Mercado')).toBeVisible();
  await expect(page.getByText('R$ 0,00 / R$ 100,00')).toBeVisible();
  await expect(page.getByText('0%', { exact: true })).toBeVisible();

  // The icon and colour have no text on the card, so check what the sheets saved.
  const { data } = await api.get(token, '/categories');
  expect(data).toEqual([
    expect.objectContaining({ name: 'Mercado', icon: 'shopping_cart', color: '#42A5F5' }),
  ]);
});

test('creates a category without a limit', async ({ page }) => {
  const { email, firstName } = await seedUser('Gabi');
  await signInThroughUi(page, { email, firstName });
  await openCategories(page);

  await page.getByRole('button', { name: 'Nova Categoria' }).click();
  await fillField(nameField(page), 'Assinaturas');
  await page.getByRole('button', { name: 'Salvar' }).click();

  await expect(page.getByText('Categoria criada.')).toBeVisible();
  await expect(page.getByText('Assinaturas')).toBeVisible();
  await expect(page.getByText('R$ 0,00 / Sem limite')).toBeVisible();
  await expect(page.getByText('--', { exact: true })).toBeVisible();
});

test('a duplicate name shows the backend error', async ({ page }) => {
  const { email, token, firstName } = await seedUser('Hugo');
  await seedCategory(token, { name: 'Mercado' });
  await signInThroughUi(page, { email, firstName });
  await openCategories(page);

  await page.getByRole('button', { name: 'Nova Categoria' }).click();
  // The uniqueness check ignores case (UniqueIgnoringCase).
  await fillField(nameField(page), 'mercado');
  await page.getByRole('button', { name: 'Salvar' }).click();

  await expect(page.getByText('Já existe uma categoria com esse nome.')).toBeVisible();
  await expect(page).toHaveURL(/#\/categories\/new/);
});

test('editing the name and limit updates the card', async ({ page }) => {
  const { email, token, firstName } = await seedUser('Iara');
  const { id } = await seedCategory(token, { name: 'Cinema', limit_amount: 200 });
  await signInThroughUi(page, { email, firstName });
  await openCategories(page);
  await expect(page.getByText('R$ 0,00 / R$ 200,00')).toBeVisible();

  await page.getByRole('button', { name: 'Editar', exact: true }).click();
  await expect(page).toHaveURL(new RegExp(`#/categories/${id}/edit`));
  await expect(page.getByText('Editar Categoria')).toBeVisible();
  await expect(nameField(page)).toHaveValue('Cinema');
  await expect(limitField(page)).toHaveValue('200,00');

  await fillField(nameField(page), 'Streaming');
  // Typed digits are cents: 35000 → 350,00.
  await fillField(limitField(page), '35000');
  await expect(limitField(page)).toHaveValue('350,00');
  await page.getByRole('button', { name: 'Salvar' }).click();

  await expect(page.getByText('Categoria atualizada.')).toBeVisible();
  await expect(page).toHaveURL(/#\/categories$/);
  await expect(page.getByText('Streaming')).toBeVisible();
  await expect(page.getByText('R$ 0,00 / R$ 350,00')).toBeVisible();
  await expect(page.getByText('Cinema')).toBeHidden();
});

test('removing a category after the confirm dialog removes its card', async ({ page }) => {
  const { email, token, firstName } = await seedUser('Joca');
  await seedCategory(token, { name: 'Academia' });
  await signInThroughUi(page, { email, firstName });
  await openCategories(page);

  await page.getByRole('button', { name: 'Editar', exact: true }).click();
  await page.getByRole('button', { name: 'Remover', exact: true }).click();
  await expect(page.getByText('Remover categoria?')).toBeVisible();
  await expect(page.getByText(/as transações dela ficam sem categoria/)).toBeVisible();
  // The dialog's "Remover" comes after the page's in the tree (if the page's is exposed at all).
  await page.getByRole('button', { name: 'Remover', exact: true }).last().click();

  await expect(page.getByText('Categoria removida.')).toBeVisible();
  await expect(page).toHaveURL(/#\/categories$/);
  await expect(page.getByText('Nenhuma categoria ainda')).toBeVisible();
  await expect(page.getByText('Academia')).toBeHidden();
});

test("a card shows this month's spend, the percent and the limit warnings", async ({ page }) => {
  const { email, token, firstName } = await seedUser('Kika');
  const near = await seedCategory(token, { name: 'Restaurantes', limit_amount: 1000 });
  const over = await seedCategory(token, { name: 'Viagens', limit_amount: 100 });
  for (const [category, amount] of [[near, 850], [over, 150]] as const) {
    await api.post(token, '/transactions', {
      type: 'expense',
      category_id: category.id,
      date: today(),
      total_amount: amount,
      description: 'Gasto e2e',
    });
  }
  await signInThroughUi(page, { email, firstName });
  await openCategories(page);

  await expect(page.getByText('R$ 850,00 / R$ 1.000,00')).toBeVisible();
  await expect(page.getByText('85%', { exact: true })).toBeVisible();
  await expect(page.getByText('Próximo do limite')).toBeVisible();

  await expect(page.getByText('R$ 150,00 / R$ 100,00')).toBeVisible();
  await expect(page.getByText('150%', { exact: true })).toBeVisible();
  await expect(page.getByText('Limite ultrapassado')).toBeVisible();
});

test('reloading the edit page loads the category by id', async ({ page }) => {
  const { email, token, firstName } = await seedUser('Lia');
  const { id } = await seedCategory(token, { name: 'Farmácia', limit_amount: 1500 });
  await signInThroughUi(page, { email, firstName });
  await openCategories(page);
  await page.getByRole('button', { name: 'Editar', exact: true }).click();
  await expect(page).toHaveURL(new RegExp(`#/categories/${id}/edit`));

  // The reload drops the Category passed as `extra`, so the page fetches GET /categories/{id}.
  await page.reload();
  await enableSemantics(page);

  await expect(page).toHaveURL(new RegExp(`#/categories/${id}/edit`));
  await expect(page.getByText('Editar Categoria')).toBeVisible();
  await expect(nameField(page)).toHaveValue('Farmácia');
  await expect(limitField(page)).toHaveValue('1.500,00');
  await expect(page.getByRole('button', { name: 'Remover', exact: true })).toBeVisible();
});

// category_form_page.dart:55-63 fills the form from the `extra` the list passed and never re-fetches.
test.fixme('the edit form shows the saved category, not the copy from the list', async ({ page }) => {
  const { email, token, firstName } = await seedUser('Malu');
  const { id } = await seedCategory(token, { name: 'Padaria' });
  await signInThroughUi(page, { email, firstName });
  await openCategories(page);
  await expect(page.getByText('Padaria')).toBeVisible();

  await api.patch(token, `/categories/${id}`, { name: 'Confeitaria' });
  await page.getByRole('button', { name: 'Editar', exact: true }).click();

  await expect(nameField(page)).toHaveValue('Confeitaria');
});
