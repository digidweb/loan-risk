require "rails_helper"

RSpec.describe ConcentrationRiskChecker do
  # Cria as regras padrão antes de cada teste
  before do
    create(:concentration_rule)           # default: 10%
    create(:concentration_rule, :for_sp)  # SP: 20%
  end

  subject(:checker) do
    described_class.new(state_code: state_code, new_amount: new_amount)
  end

  describe "carteira vazia" do
    let(:state_code) { "SP" }
    let(:new_amount) { 100_000 }

    it "aprova qualquer empréstimo quando não há carteira" do
      result = checker.call
      expect(result.approved?).to be true
    end
  end

  describe "regra padrão — máximo 10%" do
    let(:state_code) { "RJ" }

    context "quando o empréstimo não viola o limite" do
      before do
        # Carteira total: 100_000 — RJ pode ter até 10_000 (10%)
        create(:loan, state_code: "SP", amount: 90_000)
        create(:loan, state_code: "RJ", amount: 5_000)
      end

      let(:new_amount) { 4_000 }  # RJ ficaria com 9_000 / 103_000 = 8.7%

      it "aprova o empréstimo" do
        result = checker.call
        expect(result.approved?).to be true
        expect(result.reason).to be_nil
      end
    end

    context "quando o empréstimo viola o limite" do
      before do
        # Carteira total: 100_000 — RJ pode ter até 10_000 (10%)
        create(:loan, state_code: "SP", amount: 90_000)
        create(:loan, state_code: "RJ", amount: 9_000)
      end

      let(:new_amount) { 5_000 }  # RJ ficaria com 14_000 / 109_000 = 12.8%

      it "rejeita o empréstimo" do
        result = checker.call
        expect(result.approved?).to be false
        expect(result.reason).to include("RJ")
        expect(result.reason).to include("10.0%")
      end
    end
  end

  describe "exceção SP — máximo 20%" do
    let(:state_code) { "SP" }

    context "quando SP está dentro do limite de 20%" do
      before do
        create(:loan, state_code: "RJ", amount: 100_000)
        create(:loan, state_code: "SP", amount: 15_000)
      end

      let(:new_amount) { 5_000 }  # SP ficaria com 20_000 / 120_000 = 16.7%

      it "aprova o empréstimo" do
        result = checker.call
        expect(result.approved?).to be true
      end
    end

    context "quando SP ultrapassaria 20%" do
      before do
        create(:loan, state_code: "RJ", amount: 100_000)
        create(:loan, state_code: "SP", amount: 20_000)
      end

      let(:new_amount) { 10_000 }  # SP ficaria com 30_000 / 130_000 = 23%

      it "rejeita o empréstimo" do
        result = checker.call
        expect(result.approved?).to be false
        expect(result.reason).to include("SP")
        expect(result.reason).to include("20.0%")
      end
    end
  end

  describe "validações de entrada" do
    let(:state_code) { "SP" }

    it "rejeita valor zero" do
      result = described_class.new(state_code: "SP", new_amount: 0).call
      expect(result.approved?).to be false
      expect(result.reason).to include("maior que zero")
    end

    it "rejeita valor negativo" do
      result = described_class.new(state_code: "SP", new_amount: -500).call
      expect(result.approved?).to be false
    end
  end

  describe "empréstimos cancelados não entram no cálculo" do
    let(:state_code) { "RJ" }
    let(:new_amount) { 10_000 }

    before do
      create(:loan, state_code: "SP",  amount: 90_000, status: "active")
      create(:loan, state_code: "RJ",  amount: 50_000, status: "cancelled") # não conta
    end

    it "ignora empréstimos cancelados na concentração" do
      # RJ tem 0 ativos — 10_000 / 100_000 = 10% — exatamente no limite
      result = checker.call
      expect(result.approved?).to be true
    end
  end
end
