# LoansController — requisições HTTP
#
# Responsabilidade exclusiva: traduzir HTTP → Ruby e Ruby → HTTP.
# Não conhece regras de negócio. Não calcula nada.
# Delega tudo para os services e serializa a resposta.

class LoansController < ApplicationController
  # POST /loans
  def create
    result = CreateLoan.new(
      amount:     params[:amount].to_d,
      state_code: params[:state_code].to_s
    ).call

    if result.success?
      render json: serialize(result.loan), status: :created
    else
      render json: { error: result.error }, status: :unprocessable_entity
    end
  end

  # GET /loans
  def index
    loans = Loan.active.order(created_at: :desc)
    render json: loans.map { |loan| serialize(loan) }
  end

  # GET /loans/:id
  def show
    loan = Loan.find(params[:id])
    render json: serialize(loan)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Empréstimo não encontrado" }, status: :not_found
  end

  # GET /loans/concentration
  # Endpoint de consulta — mostra concentração atual por estado
  def concentration
    total = Loan.active.sum(:amount).to_d

    if total.zero?
      render json: { message: "Nenhum empréstimo ativo na carteira", total: 0 }
      return
    end

    breakdown = Loan.active
                    .group(:state_code)
                    .sum(:amount)
                    .map do |state, amount|
                      rule = ConcentrationRule.applicable_for(state)
                      pct  = amount.to_d / total

                      {
                        state:           state,
                        amount:          amount.to_f.round(2),
                        concentration:   (pct * 100).round(2),
                        limit:           rule ? (rule.max_concentration_pct * 100).round(2) : nil,
                        within_limit:    rule ? pct <= rule.max_concentration_pct : nil
                      }
                    end
                    .sort_by { |s| -s[:concentration] }

    render json: {
      portfolio_total: total.to_f.round(2),
      states:          breakdown
    }
  end

  private

  def serialize(loan)
    {
      id:         loan.id,
      amount:     loan.amount.to_f.round(2),
      state_code: loan.state_code,
      status:     loan.status,
      created_at: loan.created_at
    }
  end
end
