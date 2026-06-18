require "rails_helper"

RSpec.describe CreateLoan do
  before do
    create(:concentration_rule)           # default: 10%
    create(:concentration_rule, :for_sp)  # SP: 20%
  end

  subject(:service) { described_class.new(amount: amount, state_code: state_code) }

  context "quando os dados são válidos e o limite não é violado" do
    let(:amount)     { 10_000 }
    let(:state_code) { "SP" }

    it "cria o empréstimo com sucesso" do
      result = service.call
      expect(result.success?).to be true
      expect(result.loan).to be_persisted
      expect(result.loan.state_code).to eq("SP")
      expect(result.loan.amount).to eq(10_000)
      expect(result.loan.status).to eq("active")
    end

    it "devolve o empréstimo criado" do
      result = service.call
      expect(result.loan).to be_a(Loan)
    end
  end

  context "quando a concentração seria violada" do
    before do
      create(:loan, state_code: "SP", amount: 80_000)
      create(:loan, state_code: "RJ", amount: 20_000)
      # Carteira total: 100_000 — SP já está em 80% (muito acima dos 20%)
    end

    let(:amount)     { 1_000 }
    let(:state_code) { "SP" }

    it "não cria o empréstimo" do
      expect { service.call }.not_to change(Loan, :count)
    end

    it "retorna falha com a razão" do
      result = service.call
      expect(result.success?).to be false
      expect(result.error).to include("SP")
      expect(result.loan).to be_nil
    end
  end

  context "quando os dados são inválidos" do
    let(:state_code) { "XX" }  # UF inexistente
    let(:amount)     { 1_000 }

    it "não cria o empréstimo" do
      expect { service.call }.not_to change(Loan, :count)
    end

    it "retorna falha" do
      result = service.call
      expect(result.success?).to be false
      expect(result.error).to be_present
    end
  end

  context "quando o valor é zero" do
    let(:amount)     { 0 }
    let(:state_code) { "SP" }

    it "não cria o empréstimo" do
      expect { service.call }.not_to change(Loan, :count)
    end
  end
end
