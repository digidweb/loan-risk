# Loan Risk 💰

> A Ruby on Rails REST API for controlling geographic concentration risk in loan portfolios.

Loan Risk is a backend application designed to evaluate and control new loans against **geographic concentration limits** defined for a loan portfolio.

The project focuses on backend engineering practices such as **Domain-Driven Design, Service Objects, Transactional Consistency, Configurable Business Rules, Financial Data Modeling, and Automated Testing**.

## ✨ Features

* 💰 Create and manage loans records
* 🗺️ Calculate geographic concentration across the loan portfolio
* ⚠️ Reject loans that would exceed concentration limits
* 📊 Expose current portfolio concentration through the API
* ⚙️ Store concentration rules as database records 
* 💵 Precise monetary calculations using PostgreSQL decimal
* 🔒 Use database transactions for financial operations
* 🧪 Automated tests with RSpec
* 🏗️ Service Object architecture for business rules
* 🐳 Docker support

## 🛠️ Tech Stack

### Backend

* Ruby
* Rails
* Rails API-only
* Active Record

### Database

* PostgreSQL
  
### Architecture

* Service Objects
* Domain-driven design principles
* REST API

### Testing

* RSpec

### Infrastructure & Developement

* Docker

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

## 🛡️ Core Business Rule

When a loan is created, the system:

```text
New Loan
   │
   ▼
Calculate projected portfolio
   │
   ▼
Calculate geographic concentration
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

## 📋 Business Assumptions

The application currently follows these business assumptions:

* The total portfolio value is the sum of loans with `status: "active"`.
* Only loans with `active` status are included in concentration calculations.
* Cancelled loans are excluded from concentration calculations.
* A state-specific concentration rule overrides the default rule.
* A loan exactly at the configured concentration limit is considered approved.

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
│  Handles HTTP/JSON   │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│    Service Object    │
│                      │
│    Business rules    │
│  Concentration logic │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│        Models        │
│                      │
│      Validations     |
│      Associations    |    
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│      PostgreSQL      |
|                      |
|     Persistence      │
└──────────────────────┘
```

The main responsibility boundaries are:

* Controller → HTTP requests and responses
* Service → Business rules and risk calculation
* Model → Data integrity and validations
* Database → Persistent rules and loan data

This separation makes the business logic easier to test, maintain, and evolve independently from the HTTP layer.

## 🧠 Technical Highlights
### Domain-driven business rules

The core business requirement is geographic concentration risk.

When a new loan is created, the application evaluates how the loan would affect the portfolio's concentration in the corresponding state.

### Rule Precedence

The application supports a default concentration rule and more specific rules.

A more specific rule takes precedence over the default:
```text
Specific state rule       
        ↓
  Default rule
```

This allows the risk policy to be configured without embedding every possible rule directly into the application code.

### Business Rules as Data

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

### Financial Data Modeling

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

### Transactional Consistency

Loan creation and concentration validation are financial operations where consistency is critical. The application is designed around relational database guarantees and **ACID transactions** provided by PostgreSQL.

The goal is to ensure that the concentration check and the resulting persistence are handled consistently rather than allowing the portfolio state to become invalid between operations.

## 🔌 API

### Create a loan

```http
POST /loans
Content-Type: application/json

{
  "amount": 10000,
  "state_code": "SP"
}
```

If the new loan respects the applicable concentration limit, the API returns ```201 Created```.

If the loan would exceed the limit, the API returns ``422 Unprocessable Entity`` with an explanatory error.

Example:
```json
{
  "error": "Concentration limit exceeded for SP"
}
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

### List loans

```http
GET /loans
```

### Get a loan

```http
GET /loans/:id
```

### Get current portfolio concentration

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

## 🚀 Getting Started

### Prerequisites

Make sure you have installed:

* Ruby 3.x
* Rails 7.1
* PostgreSQL 
* Bundler
  
Or run with Docker in a containerized environment.

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

The seed data creates the initial concentration rules.

### 6. Start the API

```bash
rails server
```

The API will be available at:

```text
http://localhost:3000
```

## 🐳 Running with Docker

The repository also includes a `Dockerfile` for containerized development.

### 1. Build the image:

```bash
docker build -t loan-risk .
```

### 2. Run the container:

```bash
docker run -p 3000:3000 loan-risk
```

For a complete production-like environment, PostgreSQL should be provided as a separate service/container and configured through environment variables.

## ⚙️ Engineering Focus

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

## 🔮 Potential Improvements

If continuing the project, the following improvements would be:

* Add pagination to GET /loans
* Add API authentication and authorization
* Add rate limiting
* Add domain events for integrations
* Add caching for portfolio concentration calculations
* Add an administrative interface for managing risk rules
* Add GitHub Actions for automated tests and code quality checks
* Add API documentation with OpenAPI/Swagger

## 📌 Portfolio Context

Loan Risk is part of a portfolio focused on Ruby on Rails backend and full-stack development.

The project demonstrates practical experience with:

**Ruby on Rails · REST APIs · PostgreSQL · Active Record · Service Objects · Domain Modeling · RSpec · Docker**

More importantly, it demonstrates the ability to translate a business requirement into a maintainable backend architecture:
```text
Business requirement
        ↓
Domain model
        ↓
Business rules
        ↓
Service Object
        ↓
Database / Persistence
        ↓
API response
        ↓
Automated tests
```
The project goes beyond basic CRUD by focusing on business rules, data integrity, separation of responsibilities, and testable application architecture.

