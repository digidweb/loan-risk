# README

# Loan Risk — Controle de Risco de Concentração

API REST em Ruby on Rails para controle de risco de concentração geográfica
em carteiras de empréstimo.

---

## Decisões Técnicas

### Linguagem e Framework

**Ruby on Rails 7.1 API-only.**

- É uma stack que a empresa já usa e fácil para novos devs.
- Rails tem convenções para modelagem de domínio, validações e persistência
  perfeia para a arquiterura escolhida.
- A flag `--api` gera um app enxuto para JSON adequado para a solução.

### Banco de Dados

**PostgreSQL.**

- Em transações finaceiras a prioridade é para a consistência dos dados em
  detrimento a disponibilidade dos dados.
- O cálculo de concentração geográfica precisa de transações ACID garantidas.
- Bancos de dados relacionais são mais adequados aos princípios ACID.
- PostgreSQL é adequado para sistemas que tendem a escalar.
- O campo `amount` usa `decimal(15,2)` — nunca `float` para valores monetários,
  pois float tem erros de arredondamento binário.

### Arquitetura

**Domain-driven com Service Objects.**

Implementa os requisitos de separação de responsabilidades, manutenção do código
e evolução das regras de negócio.

Separa o projeto em três camadas bem definidas:

```
Controller  → lida com requisições
Service     → aplica as regras de negócio
Model       → valida os dados das entidades
```

### Regras como Dados

As regras de concentração geográfica estão no banco de dados e não no código.
Alterar o limite, por exemplo, de SP de 20% para 30% é uma operação de dados —
sem deploy. A tabela suporta `scope_type` e `scope_value` para receber regras
futuras por região, produto ou qualquer outro critério.

---

## Setup

```bash
# Instalar dependências
bundle install

# Criar banco de dados
rails db:create

# Rodar migrations
rails db:migrate

# Popular regras iniciais
rails db:seed

# Iniciar servidor
rails server
```

---

## Endpoints

### Criar empréstimo

```
POST /loans
Content-Type: application/json

{ "amount": 10000, "state_code": "SP" }
```

**Resposta 201 (aprovado):**

```json
{
  "id": 1,
  "amount": 10000.0,
  "state_code": "SP",
  "status": "active",
  "created_at": "2024-01-01T10:00:00.000Z"
}
```

**Resposta 422 (rejeitado):**

```json
{
  "error": "Limite de concentração excedido para SP: 25.0% projetado, limite permitido é 20.0%"
}
```

### Listar empréstimos

```
GET /loans
```

### Buscar empréstimo

```
GET /loans/:id
```

### Concentração atual da carteira

```
GET /loans/concentration
```

**Resposta:**

```json
{
  "portfolio_total": 100000.0,
  "states": [
    {
      "state": "SP",
      "amount": 60000.0,
      "concentration": 60.0,
      "limit": 20.0,
      "within_limit": false
    }
  ]
}
```

---

## Testes

```bash
# Todos os testes
bundle exec rspec

# Por camada
bundle exec rspec spec/models
bundle exec rspec spec/services
bundle exec rspec spec/requests
```

---

## Premissas

- O valor total da carteira é a soma de empréstimos com `status: "active"`
- Empréstimos cancelados saem do cálculo de concentração
- A regra mais específica tem precedência: regra por estado sobrepõe o default
- Um empréstimo exatamente no limite (= 10%) é considerado aprovado

---

## O que evoluiria com mais tempo

- Paginação em `GET /loans`
- Rate limiting na API
- Eventos de domínio (ex: `LoanCreated`) para integrações futuras
- Cache do total da carteira com invalidação no create/cancel
- Painel administrativo para gerenciar regras de concentração
