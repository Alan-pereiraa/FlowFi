# Revisão do Swagger — FlowFi API

**Data:** 27 de setembro de 2026<br>
**Base de comparação:** “Revisão do Swagger — FlowFi API”, que analisa o commit `89cac8c` da branch `feat/swagger`.<br>
**Escopo:** estado atual do workspace após as correções descritas neste relatório.

## Resumo executivo

Os cinco problemas que impediam ou comprometiam a geração foram corrigidos: a dependência está instalada e travada no Composer, as anotações estão nos controllers reais, o scanner lê os schemas, a configuração registra as rotas corretas e o servidor OpenAPI declara `/api/v1`.

As divergências de contrato destacadas no PDF também foram em sua maioria incorporadas à documentação atual. A geração foi validada no container, a especificação contém **15 paths e 30 operações**, e a interface está disponível em [http://localhost:8000/api/docs](http://localhost:8000/api/docs).

A comparação foi estática, baseada em configuração, rotas, atributos OpenAPI, Form Requests e Resources. Não foi executado um teste HTTP autenticado para cada endpoint.

## Problemas impeditivos do PDF

| Review Anterior | Estado atual | Evidência / correção |
| --- | --- | --- |
| `darkaonline/l5-swagger` não instalado nem presente no lock | **Corrigido** | A dependência consta em `packages/backend/composer.json` e `composer.lock`; o comando Artisan está disponível. |
| Cópias `*-swagger.php` duplicam controllers reais | **Não se aplica ao estado atual** | Não foram encontrados arquivos `*-swagger.php`. As operações usam atributos PHP nos controllers reais. |
| `Schemas.php` fora do escopo de leitura | **Corrigido** | `config/l5-swagger.php` usa `base_path('app')`, incluindo `app/Http/OpenAPI/Schemas.php` e os controllers. |
| Configuração incompatível com a estrutura do pacote | **Corrigido** | A configuração atual carrega o config oficial do pacote e aplica overrides do FlowFi com `array_replace_recursive`: título, caminhos de UI/JSON, diretório de anotações e flag `L5_SWAGGER_ENABLED`. |
| `/api/v1` ausente como servidor OpenAPI | **Corrigido** | `Schemas.php` declara `#[OA\Server(url: '/api/v1')]`. O Swagger UI mostra esse servidor. |

## Divergências de contrato verificadas

| Review Anterior | Estado atual |
| --- | --- |
| Respostas Resource sem envelope `data` na documentação | Schemas de resposta usam `data`; respostas paginadas também descrevem `links` e `meta`. O login é documentado separadamente como `{ user, token }`. |
| Tipo `transfer` ausente e regras de `category_id`, `goal_id` e parcelas incorretas | O schema e `StoreTransactionRequest` descrevem os três tipos e as restrições condicionais, incluindo os campos proibidos e os limites de parcelamento. |
| Limites de valores, descrição e frequência de parcelas ausentes | Estão descritos nos schemas de criação e nas regras de validação correspondentes. |
| Filtros de `GET /transactions` ausentes | A operação documenta `per_page`, `type`, `category_id`, `date_from` e `date_to`, incluindo o comportamento de paginação. |
| `PATCH /transactions/{id}` permite alterar `type` | O request proíbe `type`; a documentação descreve a resposta 422. |
| Schema Goal sem `current_amount` e User com `email_verified_at` | Goal inclui `current_amount`; o schema User corresponde aos campos do `UserResource` e não inclui `email_verified_at`. |
| Código OTP fixo em seis dígitos e cor limitada a maiúsculas | O OTP é descrito conforme `auth.otp.length` (seis por padrão); os padrões de cor aceitam maiúsculas e minúsculas. |
| Erros 429 e pagamento de parcela já paga sem documentação | As operações OTP referenciam a resposta reutilizável 429. O pagamento de parcela documenta 422 quando ela já está paga. |
| Login devolve o Model em vez de `UserResource` | O controller atual transforma o usuário em `UserResource`; a resposta documentada referencia o schema User. |
| Goals, Users, Notifications e Icons sem documentação | Os controllers atuais têm operações documentadas para esses domínios. Os schemas `Notification`, `IconCatalog` e `UpdateUserRequest` também existem. |
| Respostas reutilizáveis definidas mas sem uso | `UnauthorizedResponse`, `NotFoundResponse`, `ValidationErrorResponse` e `TooManyRequestsResponse` são referenciadas pelos controllers. |
| `SecurityScheme` mistura propriedades de `apiKey` com HTTP bearer | A definição atual usa `type: http`, `scheme: bearer` e `securityScheme: sanctum`, sem `name` ou `in`. |

## Métodos HTTP de atualização

As rotas Laravel `apiResource` expõem `PUT` e `PATCH` para Users, Goals, Categories e Transactions. O OpenAPI agora documenta os dois métodos nos controllers correspondentes. Os `PUT` usam os mesmos Form Requests e comportamento parcial dos `PATCH`, explicitado na descrição da operação.

O JSON gerado contém os operation IDs `putUser`, `putGoal`, `putCategory` e `putTransaction`.

## URLs e configuração

- Swagger UI: `http://localhost:8000/api/docs`
- Especificação JSON: `http://localhost:8000/api/docs.json`
- Arquivo gerado: `packages/backend/storage/api-docs/api-docs.json`
- Servidor da API: `/api/v1`

O guia [packages/backend/docs/swagger-setup.md](../packages/backend/docs/swagger-setup.md) foi atualizado com essas URLs e com a lista de atributos, incluindo `OA\Put`.

## Itens ainda dispensáveis ou pendentes

- `app/Providers/OpenAPIServiceProvider.php` não está registrado e não é necessário para o package discovery do L5 Swagger.
- `routes/swagger.php` continua sendo um placeholder sem rotas, e não é carregado pelo bootstrap atual.
- Endpoints de device token, mencionados como trabalho futuro no PDF, devem ser documentados quando existirem/forem integrados.

Os dois primeiros itens são limpeza possível, não bloqueiam geração ou acesso à interface, e não foram removidos nesta correção.

## Validação executada

1. `docker compose exec -T api php artisan optimize:clear`
2. `docker compose exec -T api php artisan l5-swagger:generate` — concluiu sem erro.
3. `docker compose exec -T api php artisan route:list --name=l5-swagger` — registrou `/api/docs` e `/api/docs.json`.
4. `docker compose exec -T api php artisan route:list --path=api/v1` — confirmou as rotas reais, incluindo `PUT|PATCH` nos quatro recursos.
5. Inspeção do JSON gerado — 15 paths, 30 operações e os quatro operation IDs de PUT.
6. Abertura da UI no navegador — título, servidor `/api/v1` e grupos de operações carregaram.

Não foi executada uma bateria de requests autenticadas comparando cada resposta real com o schema OpenAPI; essa continua sendo a verificação recomendada para uma revisão contratual completa.
