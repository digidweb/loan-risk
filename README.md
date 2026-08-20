# Loan Risk 💰

> A Ruby on Rails REST API for managing geographic concentration risk in loan portfolios.

Loan Risk is a backend application designed to monitor and control **geographic concentration risk** in a loan portfolio.

When a new loan is created, the API calculates its impact on the portfolio's geographic concentration and verifies whether the applicable concentration limit would be exceeded.

The project focuses on backend engineering practices such as **domain-driven design, Service Objects, transactional consistency, configurable business rules, financial data modeling, and automated testing**.

## ✨ Features

* 💰 Create and manage loans
* 🗺️ Monitor geographic concentration by state
* ⚠️ Reject loans that would exceed concentration limits
* 📊 Calculate the current concentration of the portfolio
* ⚙️ Store concentration rules as database records instead of hardcoding them
* 🔀 Support default and state-specific concentration rules
* 💵 Use precise decimal types for monetary values
* 🔒 Use database transactions for financial operations
* 🧪 Automated tests with RSpec
* 🏗️ Service Object architecture for business rules

## 🛠️ Tech Stack

| Layer        | Technology                               |
| ------------ | ---------------------------------------- |
| Language     | Ruby                                     |
| Framework    | Ruby on Rails 7.1                        |
| Application  | Rails API-only                           |
| Database     | PostgreSQL                               |
| Testing      | RSpec                                    |
| Architecture | Service Objects / Domain-oriented design |
| API          | REST / JSON                              |

## 🎯 Business Problem

Loan portfolios can become excessively concentrated in a specific geographic region.

For example, suppose a portfolio has a maximum concentration limit of **20% per state**.

If the portfolio currently contains:

```text
Total portfolio: R$ 100,000

São Paulo (SP): R$ 15,000
Current concentration: 15%
```

A new loan of:

```text
R$ 10,000 → SP
```

would result in:

```text
Projected SP exposure: R$ 25,000
Projected concentration: 25%
Allowed limit: 20%
```

The API therefore rejects the new loan because accepting it would violate the configured concentration limit.

This business rule is the core of the application.

## 🧠 Core Business Rule

When a loan is created, the system:

```text
New Loan
   │
   ▼
Determine applicable rule
   │
   ▼
Calculate projected portfolio concentration
   │
   ▼
Compare against configured limit
   │
   ├───────────────┐
   │               │
   ▼               ▼
Within limit    Exceeds limit
   │               │
   ▼               ▼
Approve         Reject
   │
   ▼
Persist loan
```

The concentration calculation considers only loans with:

```text
status: "active"
```

Cancelled loans are excluded from the portfolio concentration calculation.

## 🏗️ Architecture

The application uses a domain-oriented architecture with **Service Objects** to keep business rules separate from controllers and persistence concerns.

```text
┌──────────────────────┐
│      HTTP Client     │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│      Controller      │
│                      │
│ Handles HTTP/JSON    │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│       Service        │
│                      │
│ Business rules       │
│ Concentration logic  │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│        Models        │
│                      │
│ Validations          │
│ Persistence          │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│      PostgreSQL      │
└──────────────────────┘
```

This separation makes the business logic easier to test, maintain, and evolve independently from the HTTP layer.

## ⚙️ Business Rules as Data

A key design decision in Loan Risk is to store concentration rules in the database instead of hardcoding them in Ruby.

For example:

```text
scope_type:  "state"
scope_value: "SP"
limit:       20%
```

Changing the limit from:

```text
20% → 30%
```

becomes a **data operation rather than a code change**.

This means that changing a business configuration does not require modifying the application code or deploying a new version.

The rule model also supports:

* `scope_type`
* `scope_value`

This allows the system to evolve toward rules based on other dimensions, such as:

* Region
* Product
* Customer segment
* Portfolio
* Other business criteria

## 💵 Financial Data Modeling

Monetary values are stored using:

```ruby
decimal(15, 2)
```

rather than floating-point types.

This is intentional because floating-point arithmetic can introduce binary rounding errors that are inappropriate for financial calculations.

For example, a monetary value such as:

```text
10000.00
```

should be represented precisely rather than relying on floating-point arithmetic.

## 🔒 Transactional Consistency

Loan creation and concentration validation are financial operations where consistency is critical.

The application is designed around relational database guarantees and **ACID transactions** provided by PostgreSQL.

The goal is to ensure that the concentration check and the resulting persistence are handled consistently rather than allowing the portfolio state to become invalid between operations.

## 🔌 API

### Create a loan

```http
POST /loans
Content-Type: application/json
```

Request:

```json
{
  "amount": 10000,
  "state_code": "SP"
}
```

### Approved response

```http
HTTP/1.1 201 Created
```

```json
{
  "id": 1,
  "amount": 10000.0,
  "state_code": "SP",
  "status": "active",
  "created_at": "2024-01-01T10:00:00.000Z"
}
```

### Rejected response

```http
HTTP/1.1 422 Unprocessable Entity
```

```json
{
  "error": "Concentration limit exceeded for SP: 25.0% projected, allowed limit is 20.0%"
}
```

## List loans

```http
GET /loans
```

## Get a loan

```http
GET /loans/:id
```

## Get current portfolio concentration

```http
GET /loans/concentration
```

Example response:

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

## 📋 Assumptions

The application currently follows these business assumptions:

* The total portfolio value is the sum of loans with `status: "active"`.
* Cancelled loans are excluded from concentration calculations.
* The most specific rule takes precedence over the default rule.
* A state-specific rule overrides the default rule.
* A loan exactly at the configured concentration limit is considered approved.

## 🧪 Testing

The project uses **RSpec** to test the application's behavior at different layers.

Run the complete test suite:

```bash
bundle exec rspec
```

Run model specs:

```bash
bundle exec rspec spec/models
```

Run service specs:

```bash
bundle exec rspec spec/services
```

Run request specs:

```bash
bundle exec rspec spec/requests
```

The test structure mirrors the application's architecture, making it possible to test:

```text
Models
   ↓
Services
   ↓
HTTP Requests
```

This helps ensure that both individual business rules and complete API flows are covered.

## 📁 Project Structure

```text
app/
├── controllers/
│   └── ...              # HTTP/API layer
│
├── models/
│   └── ...              # Domain entities and validations
│
└── services/
    └── ...              # Business rules

spec/
├── models/
│   └── ...              # Model specs
│
├── services/
│   └── ...              # Business logic specs
│
└── requests/
    └── ...              # API/request specs

db/
├── migrate/
│   └── ...              # Database migrations
│
└── seeds.rb             # Initial concentration rules
```

## 🚀 Getting Started

### Prerequisites

Make sure you have the following installed:

* Ruby
* Bundler
* Ruby on Rails 7.1
* PostgreSQL

### 1. Clone the repository

```bash
git clone https://github.com/digidweb/loan-risk.git
cd loan-risk
```

### 2. Install dependencies

```bash
bundle install
```

### 3. Create the database

```bash
rails db:create
```

### 4. Run migrations

```bash
rails db:migrate
```

### 5. Load the initial rules

```bash
rails db:seed
```

### 6. Start the API

```bash
rails server
```

The API will be available at:

```text
http://localhost:3000
```

## 🐳 Running with Docker

The repository also includes a `Dockerfile` and Docker-related configuration.

Build the image:

```bash
docker build -t loan-risk .
```

Run the container:

```bash
docker run -p 3000:3000 loan-risk
```

For a complete production-like environment, PostgreSQL should be provided as a separate service/container and configured through environment variables.

## 💡 Technical Takeaways

Loan Risk was designed to explore backend engineering problems that go beyond basic CRUD operations.

The main concepts explored are:

* Designing a RESTful API with Rails API-only
* Modeling a financial domain with PostgreSQL
* Representing monetary values with precise decimal types
* Separating business logic using Service Objects
* Keeping business rules configurable as data
* Applying database transactions to financial operations
* Handling domain-specific validation and rejection
* Testing models, services, and API requests with RSpec
* Designing an architecture that can evolve as business rules become more complex

## 🔮 Potential Improvements

If continuing the project, the following improvements would be natural next steps:

* Add pagination to `GET /loans`
* Add API rate limiting
* Introduce domain events such as `LoanCreated`
* Add asynchronous processing where appropriate
* Cache portfolio totals with proper invalidation
* Add an administrative interface for managing concentration rules
* Add API documentation with OpenAPI/SwaggerAproveite
* Add authentication and authorization
* Add database indexes for frequently queried fields
* Add GitHub Actions for automated RSpec and RuboCop checks
* Add production deployment and monitoring
* Add structured logging and error tracking

## 🎯 Engineering Focus

The main purpose of this project is to demonstrate how a relatively simple business requirement can be translated into a maintainable backend architecture.

The application intentionally separates:

```text
HTTP concerns
     ↓
Business rules
     ↓
Domain entities
     ↓
Database persistence
```

This makes it possible to evolve the business rules without coupling them directly to the API controllers or database implementation.

## 📄 Project Context

Loan Risk is a personal backend project created to practice Ruby on Rails API development and explore the design of systems involving financial business rules.

The project focuses particularly on **domain modeling, Service Objects, PostgreSQL transactions, configurable business rules, precise monetary values, and automated testing**.Aproveite

