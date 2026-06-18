# ConcentrationRule — regras de negócio
#
# Decisão de design: regras como dados, não como código.
# Mudar de 10% para 15% é uma operação administrativa, não um deploy.
#
# scope_type define a dimensão da regra:
#   "default" → fallback para qualquer estado sem regra específica
#   "state"   → regra para um estado específico (ex: SP)
#   "region"  → exercício extra — regra para uma região (ex: Sudeste)

class ConcentrationRule < ApplicationRecord
  SCOPE_TYPES = %w[default state region].freeze

  validates :scope_type,
            presence: true,
            inclusion: { in: SCOPE_TYPES }

  validates :max_concentration_pct,
            presence: true,
            numericality: {
              greater_than:              0,
              less_than_or_equal_to:     1,
              message: "deve estar entre 0 e 1 (ex: 0.20 para 20%)"
            }

  validates :active, inclusion: { in: [true, false] }

  # Scopes
  scope :active,       -> { where(active: true) }
  scope :for_state,    ->(state) { where(scope_type: "state", scope_value: state.to_s.upcase) }
  scope :for_region,   ->(region) { where(scope_type: "region", scope_value: region) }
  scope :default_rule, -> { where(scope_type: "default", scope_value: nil) }

  # Busca a regra aplicável para um estado — específica ou fallback
  # Essa lógica de precedência fica no model porque é uma consulta de domínio
  def self.applicable_for(state_code)
    for_state(state_code).active.first ||
      default_rule.active.first
  end
end
