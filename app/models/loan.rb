# Loan — entidade central do domínio
#
# Responsabilidade: representar UM empréstimo e validar seus dados intrínsecos.
#
# O que NÃO é responsabilidade deste model:
#   - Calcular concentração da carteira → ConcentrationRiskChecker
#   - Orquestrar o fluxo de criação    → CreateLoan service
#
# As validações aqui são validações de ENTIDADE — o que torna um empréstimo
# individualmente válido, independente de qualquer regra da carteira de empréstimos.

class Loan < ApplicationRecord
  BRAZILIAN_STATES = %w[
    AC AL AP AM BA CE DF ES GO MA MT MS MG PA PB PR PE PI
    RJ RN RS RO RR SC SP SE TO
  ].freeze

  STATUSES = %w[active cancelled].freeze

  # Validações de entidade
  validates :amount,
            presence: true,
            numericality: {
              greater_than: 0,
              message: "deve ser maior que zero"
            }

  validates :state_code,
            presence: true,
            inclusion: {
              in:      BRAZILIAN_STATES,
              message: "%{value} não é uma UF válida"
            }

  validates :status,
            inclusion: { in: STATUSES }

  # Scopes — queries reutilizáveis que espelham conceitos do domínio
  scope :active,   -> { where(status: "active") }
  scope :by_state, ->(state) { where(state_code: state.to_s.upcase) }

  # Comportamento de domínio
  def cancel!
    raise Loan::AlreadyCancelledError, "Empréstimo já está cancelado" if cancelled?
    update!(status: "cancelled")
  end

  def active?
    status == "active"
  end

  def cancelled?
    status == "cancelled"
  end

  # Erros tipados — permitem tratamento preciso na camada acima
  class AlreadyCancelledError < StandardError; end
end
