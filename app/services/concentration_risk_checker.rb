# ConcentrationRiskChecker — regra de negócio central do sistema
#
# Responsabilidade ÚNICA: calcular se um novo empréstimo violaria
# o limite de concentração geográfica da carteira de empréstimos.
#
# Por que é um Service Object e não um método do model Loan?
#   A regra depende do estado AGREGADO de toda a carteira — não é
#   uma propriedade de um único empréstimo. Um model não deve
#   consultar outros models para se validar.
#
# Interface pública: apenas #call — padrão de service objects em Ruby.
# Retorna um Result struct — evita retornar arrays ou hashes soltos,
# tornando o contrato explícito e o código no chamador mais legível.
#
# Pode ser chamado independentemente de CreateLoan — útil para um
# endpoint de simulação futuro: "esse empréstimo seria aprovado?"

# Fórmula correta de concentração projetada:
#
#   concentração projetada = (estado_atual + novo_valor)
#                            ─────────────────────────────────
#                            (carteira_atual + novo_valor)
#
# Exemplo com carteira de R$ 1.000.000:
#   SP atual:  R$ 150.000 (15% da carteira)
#   Novo loan: R$ 100.000
#   SP projetado: 250.000 / 1.100.000 = 22,7% → excede limite de 20% → REJEITA

class ConcentrationRiskChecker
  # Contrato de retorno — imutável e explícito
  Result = Struct.new(:approved?, :reason, keyword_init: true)

  def initialize(state_code:, new_amount:)
    @state_code = state_code.to_s.upcase
    @new_amount = new_amount.to_d
  end

  def call
    return invalid_amount_result if @new_amount <= 0
    return approved_result       if portfolio_total.zero?

    rule = ConcentrationRule.applicable_for(@state_code)
    return missing_rule_result if rule.nil?

    projected_state_total = state_total + @new_amount
    projected_portfolio_total = portfolio_total + @new_amount
    projected_pct = projected_state_total / projected_portfolio_total

    if projected_pct > rule.max_concentration_pct
      rejected_result(
        state: @state_code,
        projected_pct: projected_pct,
        limit: rule.max_concentration_pct
      )
    else
      approved_result
    end
  end

  private

  # Usa memoização — a carteira total é consultada uma única vez por chamada
  def portfolio_total
    @portfolio_total ||= Loan.active.sum(:amount).to_d
  end

  def state_total
    @state_total ||= Loan.active.by_state(@state_code).sum(:amount).to_d
  end

  # Construtores de Result — centralizados para fácil manutenção

  def approved_result
    Result.new(approved?: true, reason: nil)
  end

  def rejected_result(state:, projected_pct:, limit:)
    Result.new(
      approved?: false,
      reason: "Limite de concentração excedido para #{state}: " \
              "#{format_pct(projected_pct)} projetado, " \
              "limite permitido é #{format_pct(limit)}"
    )
  end

  def invalid_amount_result
    Result.new(
      approved?: false,
      reason: 'Valor do empréstimo deve ser maior que zero'
    )
  end

  def missing_rule_result
    Result.new(
      approved?: false,
      reason: "Nenhuma regra de concentração configurada para #{@state_code}"
    )
  end

  def format_pct(value)
    "#{(value * 100).round(2)}%"
  end
end
