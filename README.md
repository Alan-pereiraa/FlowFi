# FlowFi

FlowFi é um app de controle financeiro pessoal. A ideia é permitir que o usuário organize
sua vida financeira em três eixos:

- **Metas (Goals)** — quanto quer economizar para algo, com um valor-alvo e um prazo opcional.
- **Categorias (Categories)** — como os gastos são classificados, cada uma com um teto de
  gasto opcional.
- **Transações e parcelas** — o registro de entradas e saídas, ligado a uma categoria e,
  quando fizer sentido, a uma meta (ainda não implementado).

O login é **sem senha**: o usuário recebe um código de 6 dígitos por e-mail e o troca por um
token de acesso.

## Estrutura do repositório

Monorepo com dois pacotes:

```
FlowFi/
├── packages/backend    # API em Laravel (PHP 8.3, SQLite, Sanctum)
└── platform/frontend   # App em Flutter
```

## Arquitetura

O backend é uma API em **Laravel 12** (PHP 8.3), com banco **SQLite** e autenticação via
**Laravel Sanctum** (tokens de API). O código de negócio é organizado por **domínio**: cada
área (usuários/autenticação, metas/categorias, etc.) vive em sua própria pasta com seus
próprios controllers, models, regras de negócio e rotas, em vez de ficar tudo misturado por
tipo de arquivo.

## Como rodar com Docker

```sh
docker compose up --build
```
