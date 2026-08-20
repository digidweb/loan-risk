# README

# Loan Risk — Concentration Risk Management

REST API built with Ruby on Rails for managing geographic concentration risk in loan portfolios.

---

## Technical Decisions

### Language and Framework

**Ruby on Rails 7.1 API-only.**

* It is a technology stack already used by the company and is easy for new developers to adopt.
* Rails provides conventions for domain modeling, validations, and persistence that are well suited to the chosen architecture.
* The `--api` flag generates a lightweight JSON-focused application that is appropriate for this solution.

### Database

**PostgreSQL.**

* In financial transactions, data consistency is prioritized over data availability.
* Geographic concentration calculations require guaranteed ACID transactions.
* Relational databases are better suited to ACID principles.
* PostgreSQL is well suited for systems that are expected to scale.
* The `amount` field uses `decimal(15,2)` — never `float` for monetary values, as floating-point numbers can introduce binary rounding errors.

### Architecture

**Domain-driven architecture with Service Objects.**

This approach addresses the requirements for separation of concerns, code maintainability, and the evolution of business rules.

The project is divided into three clearly defined layers:

```text
Controller  → handles requests
Service     → applies business rules
Model       → validates entity data
```

### Rules as Data

Geographic concentration rules are stored in the database rather than hardcoded in the application.

For example, changing the concentration limit for São Paulo (SP) from 20% to 30% is a data operation — no deployment is required.

The table supports `scope_type` and `scope_value`, allowing future rules to be defined by region, product, or any other criteria.

---

## Setup

```bash
# Install dependencies
bundle install

# Create the database
rails db:create

# Run migrations
rails db:migrate

# Seed initial rules
rails db:seed

# Start the server
rails server
```

---

## Endpoints

### Create a loan

```http
POST /loans
Content-Type: application/json

{ "amount": 10000, "state_code": "SP" }
```

**201 Response (approved):**

```json
{
  "id": 1,
  "amount": 10000.0,
  "state_code": "SP",
  "status": "active",
  "created_at": "2024-01-01T10:00:00.000Z"
}
```

**422 Response (rejected):**

```json
{
  "error": "Concentration limit exceeded for SP: 25.0% projected, allowed limit is 20.0%"
}
```

### List loans

```http
GET /loans
```

### Get a loan

```http
GET /loans/:id
```

### Current portfolio concentration

```http
GET /loans/concentration
```

**Response:**

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

## Tests

```bash
# Run all tests
bundle exec rspec

# Run tests by layer
bundle exec rspec spec/models
bundle exec rspec spec/services
bundle exec rspec spec/requests
```

---

## Assumptions

* The total portfolio value is the sum of loans with `status: "active"`.
* Cancelled loans are excluded from concentration calculations.
* The most specific rule takes precedence: a state-specific rule overrides the default rule.
* A loan exactly at the limit (= 10%) is considered approved.

---

## What I Would Improve With More Time

* Pagination for `GET /loans`
* API rate limiting
* Domain events (e.g., `LoanCreated`) for future integrations
* Portfolio total caching with invalidation on loan creation/cancellation
* Administrative dashboard for managing concentration rules


# Loan Risk — Concentration Risk Management

REST API built with Ruby on Rails for managing geographic concentration risk in loan portfolios.

---

## Technical Decisions

### Language and Framework

**Ruby on Rails 7.1 API-only.**

* It is a technology stack already used by the company and is easy for new developers to adopt.
* Rails provides conventions for domain modeling, validations, and persistence that are well suited to the chosen architecture.
* The `--api` flag generates a lightweight JSON-focused application that is appropriate for this solution.

### Database

**PostgreSQL.**

* In financial transactions, data consistency is prioritized over data availability.
* Geographic concentration calculations require guaranteed ACID transactions.
* Relational databases are better suited to ACID principles.
* PostgreSQL is well suited for systems that are expected to scale.
* The `amount` field uses `decimal(15,2)` — never `float` for monetary values, as floating-point numbers can introduce binary rounding errors.

### Architecture

**Domain-driven architecture with Service Objects.**

This approach addresses the requirements for separation of concerns, code maintainability, and the evolution of business rules.

The project is divided into three clearly defined layers:

```text
Controller  → handles requests
Service     → applies business rules
Model       → validates entity data
```

### Rules as Data

Geographic concentration rules are stored in the database rather than hardcoded in the application.

For example, changing the concentration limit for São Paulo (SP) from 20% to 30% is a data operation — no deployment is required.

The table supports `scope_type` and `scope_value`, allowing future rules to be defined by region, product, or any other criteria.

---

## Setup

```bash
# Install dependencies
bundle install

# Create the database
rails db:create

# Run migrations
rails db:migrate

# Seed initial rules
rails db:seed

# Start the server
rails server
```

---

## Endpoints

### Create a loan

```http
POST /loans
Content-Type: application/json

{ "amount": 10000, "state_code": "SP" }
```

**201 Response (approved):**

```json
{
  "id": 1,
  "amount": 10000.0,
  "state_code": "SP",
  "status": "active",
  "created_at": "2024-01-01T10:00:00.000Z"
}
```

**422 Response (rejected):**

```json
{
  "error": "Concentration limit exceeded for SP: 25.0% projected, allowed limit is 20.0%"
}
```

### List loans

```http
GET /loans
```

### Get a loan

```http
GET /loans/:id
```

### Current portfolio concentration

```http
GET /loans/concentration
```

**Response:**

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

## Tests

```bash
# Run all tests
bundle exec rspec

# Run tests by layer
bundle exec rspec spec/models
bundle exec rspec spec/services
bundle exec rspec spec/requests
```

---

## Assumptions

* The total portfolio value is the sum of loans with `status: "active"`.
* Cancelled loans are excluded from concentration calculations.
* The most specific rule takes precedence: a state-specific rule overrides the default rule.
* A loan exactly at the limit (= 10%) is considered approved.

---

## What I Would Improve With More Time

* Pagination for `GET /loans`
* API rate limiting
* Domain events (e.g., `LoanCreated`) for future integrations
* Portfolio total caching with invalidation on loan creation/cancellation
* Administrative dashboard for managing concentration rules
