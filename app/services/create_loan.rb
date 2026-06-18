#   - advisory lock do PostgreSQL: garante que apenas uma operação
#     de criação de empréstimo ocorre por vez no banco inteiro
#   - a verificação e o save dentro da mesma transação:
#     se a verificação passa mas o save falha, nada é persistido
#     e o lock é liberado

class CreateLoan
  Result = Struct.new(:success?, :loan, :error, keyword_init: true)

  # Lock exclusivo a nível de aplicação — número arbitrário único
  # para identificar a operação de criação de empréstimo
  ADVISORY_LOCK_KEY = 20_240_101

  def initialize(amount:, state_code:)
    @amount     = amount.to_d
    @state_code = state_code.to_s.upcase
  end

  def call
    ActiveRecord::Base.transaction do
      # Adquire lock exclusivo no PostgreSQL durante a transação
      # Bloqueia qualquer outro processo que tente o mesmo lock
      # até essa transação terminar (commit ou rollback)
      acquire_lock!

      # Verificação acontece DENTRO da transação com lock —
      # nenhum outro processo pode inserir um empréstimo
      # enquanto estamos verificando e salvando
      check = ConcentrationRiskChecker.new(
        state_code: @state_code,
        new_amount: @amount
      ).call

      return failure_result(check.reason) unless check.approved?

      loan = Loan.new(
        amount: @amount,
        state_code: @state_code
      )

      if loan.save
        success_result(loan)
      else
        failure_result(loan.errors.full_messages.join(', '))
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    failure_result(e.message)
  end

  private

  def acquire_lock!
    result = ActiveRecord::Base.connection.execute(
      "SELECT pg_try_advisory_xact_lock(#{ADVISORY_LOCK_KEY}) AS locked"
    )

    locked = result.first['locked']

    # Normaliza o retorno — pode ser booleano true ou string "t"
    # dependendo da versão do driver pg
    return if [true, 't'].include?(locked)

    raise 'Sistema ocupado processando outro empréstimo. Tente novamente.'
  end

  def success_result(loan)
    Result.new(success?: true, loan: loan, error: nil)
  end

  def failure_result(error)
    Result.new(success?: false, loan: nil, error: error)
  end
end
