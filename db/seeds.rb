# Seeds — estado inicial das regras de concentração
#
# Idempotente: pode ser rodado múltiplas vezes sem duplicar dados.
# Em produção, alterações de regras seriam feitas via painel administrativo
# ou migration de dados — nunca hardcoded no código.

puts "Limpando regras existentes..."
ConcentrationRule.delete_all

puts "Criando regras de concentração..."

# Regra padrão — todos os estados: máximo 10%
ConcentrationRule.create!(
  scope_type:            "default",
  scope_value:           nil,
  max_concentration_pct: 0.10,
  active:                true,
  effective_from:        Date.today
)

# Exceção SP — máximo 20%
ConcentrationRule.create!(
  scope_type:            "state",
  scope_value:           "SP",
  max_concentration_pct: 0.20,
  active:                true,
  effective_from:        Date.today
)

puts "✅ #{ConcentrationRule.count} regras criadas:"
ConcentrationRule.all.each do |rule|
  scope = rule.scope_value || "padrão"
  limit = (rule.max_concentration_pct * 100).round
  puts "   #{scope}: #{limit}%"
end
