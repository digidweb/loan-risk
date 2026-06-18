# Decisões técnicas:
#
# - amount como decimal(15,2): precisão financeira obrigatória — nunca Float para dinheiro
# - state_code limit 2: UF brasileira sempre tem exatamente 2 caracteres
# - status com default "active": permite cancelamento futuro sem quebrar cálculo
#   de concentração — empréstimos cancelados saem automaticamente do cálculo
# - índice composto [state_code, status]: a query de concentração filtra por
#   ambas as colunas — esse índice é crítico para performance da carteira

class CreateLoans < ActiveRecord::Migration[7.1]
  def change
    create_table :loans do |t|
      t.decimal :amount,     precision: 15, scale: 2, null: false
      t.string  :state_code, limit: 2,                null: false
      t.string  :status,     default: "active",       null: false

      t.timestamps
    end

    add_index :loans, :state_code
    add_index :loans, :status
    add_index :loans, [:state_code, :status]
  end
end
