# Decisões técnicas:
#
# Regras de concentração são DADOS DE NEGÓCIO
# Colocá-las no banco permite alterá-las sem deploy
#
# - scope_type + scope_value: generaliza para qualquer critério futuro
#     scope_type="default", scope_value=nil   → regra padrão (fallback)
#     scope_type="state",   scope_value="SP"  → regra por estado
#     scope_type="region",  scope_value="SE"  → regra por região (exercício extra)
#
# - max_concentration_pct decimal(5,4): 0.2000 = 20%, sem ambiguidade
# - active boolean: permite ativar/desativar regras sem deletar dados históricos

class CreateConcentrationRules < ActiveRecord::Migration[7.1]
  def change
    create_table :concentration_rules do |t|
      t.string  :scope_type,                          null: false
      t.string  :scope_value
      t.decimal :max_concentration_pct, precision: 5,
                                        scale: 4,     null: false
      t.boolean :active,                default: true, null: false
      t.date    :effective_from
      t.date    :effective_until

      t.timestamps
    end

    add_index :concentration_rules, [:scope_type, :scope_value, :active],
              name: "index_concentration_rules_on_scope_and_active"
  end
end
