# Swagger / OpenAPI

A documentação da API é gerada a partir de atributos do PHP 8 (`#[OA\Get(...)]`, `#[OA\Schema(...)]`, com `use OpenApi\Attributes as OA;`) lidos pelo pacote `darkaonline/l5-swagger`, e exibida no Swagger UI. Não use comentários `@OA\...`: eles só funcionam com o pacote `doctrine/annotations` instalado.

## Instalação (uma vez, dentro do container `api`)

```bash
composer require --dev darkaonline/l5-swagger
php artisan vendor:publish --provider "L5Swagger\L5SwaggerServiceProvider"
```

O `composer require` atualiza `composer.json` e `composer.lock` juntos; commite os dois. No arquivo `config/l5-swagger.php` publicado, ajuste o `title` para `FlowFi API` e confirme que `annotations` contém `base_path('app')` (é o padrão do pacote).

## Gerar e acessar

```bash
php artisan l5-swagger:generate
```

- **Swagger UI:** http://localhost:8000/api/docs
- **Spec gerada:** http://localhost:8000/api/docs.json (arquivo em `storage/api-docs/api-docs.json`)

Rode o `generate` sempre que mudar uma anotação. Em desenvolvimento, `L5_SWAGGER_GENERATE_ALWAYS=true` no `.env` regenera a cada request.

## Testar endpoints protegidos

1. Em `POST /auth/otp/request`, envie o e-mail (o código chega no Mailpit).
2. Em `POST /auth/otp/verify`, envie e-mail e código e copie o `token` da resposta.
3. Clique em **Authorize** no topo do Swagger UI e cole o token (sem o prefixo `Bearer`).

O servidor declarado é `/api/v1`, então os paths na documentação (`/transactions`, `/goals`, ...) não repetem o prefixo.

## Onde ficam as anotações

| O quê | Onde |
| --- | --- |
| Info, server, security scheme, tags, schemas e responses reutilizáveis | `app/Http/OpenAPI/Schemas.php` |
| Parâmetros reutilizáveis (`IdPath`) | `app/Http/OpenAPI/Parameters.php` (em classe separada: o swagger-php anexa `#[OA\Schema]` irmãos a um `#[OA\Parameter]` da mesma classe) |
| Cada endpoint | Atributo `#[OA\Get/Post/Put/Patch/Delete(...)]` no método do controller real, em `app/Domains/*/Controllers` |

Não crie cópias dos controllers só para documentar: elas declaram a mesma classe duas vezes e quebram o autoload e o gerador.

## Regras para manter a doc fiel à API

- **Fonte de verdade:** `rules()` dos Form Requests e `toArray()` dos Resources. Confira cada campo neles.
- **Envelope `data`:** todo `JsonResource` embrulha a resposta em `{ "data": ... }`. Listas paginadas também trazem `links` e `meta`. Use os schemas `*Response`, `*ListResponse` e `*PageResponse`.
- **Exceção:** `POST /auth/otp/verify` devolve `{ "user": {...}, "token": "..." }` sem `data`.
- **Erros:** reutilize `#/components/responses/UnauthorizedResponse`, `NotFoundResponse`, `ValidationErrorResponse` e `TooManyRequestsResponse`.
- **Valores monetários** são strings decimais com 2 casas (`"150.50"`).
- **Novo endpoint ou campo:** adicione o atributo no método, atualize o schema em `Schemas.php`, rode `l5-swagger:generate` e compare `api-docs.json` com uma resposta real (`curl -H "Authorization: Bearer <token>" http://localhost:8000/api/v1/transactions`).

## Pendente

Os endpoints de device token (branch `feat/notifications`) precisam ser documentados depois do merge.

## Troubleshooting

- **`Required @OA\Info() not found`:** o gerador não está lendo `app/Http/OpenAPI/Schemas.php`; confira a lista `annotations` do config.
- **"Try it out" dá 404:** confira se o `@OA\Server(url="/api/v1")` continua em `Schemas.php`.
- **Endpoint sumiu da doc:** rode `php artisan l5-swagger:generate` e veja os warnings do comando; um `$ref` apontando para schema inexistente aparece ali.
