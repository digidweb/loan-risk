# CreateLoan — orquestra o fluxo completo de criação de empréstimo
#
# Responsabilidade: coordenar a sequência correta de operações:
#   1. Verificar regra de concentração (delega para ConcentrationRiskChecker)
#   2. Persistir o empréstimo se aprovado
#   3. Devolver um resultado estruturado ao chamador
#
# Por que separar CreateLoan de ConcentrationRiskChecker?
#   ConcentrationRiskChecker pode ser chamado de forma independente —
#   por exemplo, em um endpoint de simulação que verifica sem criar.
#   Se estivessem juntos, seria impossível reutilizar só a verificação.
#
# A transação garante atomicidade: se o save falhar após a verificação
# passar (ex: violação de constraint no banco), nada é persistido.

class CreateLoan
  Result = Struct.new(:success?, :loan, :error, keyword_init: true)

  def initialize(amount:, state_code:)
    @amount     = amount
    @state_code = state_code
  end

  def call
    # Passo 1 — verifica concentração ANTES de qualquer persistência
    check = ConcentrationRiskChecker.new(
      state_code: @state_code,
      new_amount: @amount
    ).call

    return failure_result(check.reason) unless check.approved?

    # Passo 2 — persiste dentro de transação atômica
    # Se qualquer coisa falhar aqui, o banco faz rollback completo
    ActiveRecord::Base.transaction do
      loan = Loan.new(
        amount:     @amount,
        state_code: @state_code.to_s.upcase
      )

      if loan.save
        return success_result(loan)
      else
        return failure_result(loan.errors.full_messages.join(", "))
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    failure_result(e.message)
  end

  private

  def success_result(loan)
    Result.new(success?: true, loan: loan, error: nil)
  end

  def failure_result(error)
    Result.new(success?: false, loan: nil, error: error)
  end
end
