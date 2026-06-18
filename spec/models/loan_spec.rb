require "rails_helper"

RSpec.describe Loan, type: :model do
  describe "validações de entidade" do
    it { should validate_presence_of(:amount) }
    it { should validate_presence_of(:state_code) }

    context "amount" do
      it "rejeita valor zero" do
        loan = build(:loan, amount: 0)
        expect(loan).not_to be_valid
        expect(loan.errors[:amount]).to include("deve ser maior que zero")
      end

      it "rejeita valor negativo" do
        loan = build(:loan, amount: -100)
        expect(loan).not_to be_valid
      end

      it "aceita valor positivo" do
        loan = build(:loan, amount: 1000)
        expect(loan).to be_valid
      end
    end

    context "state_code" do
      it "aceita UFs válidas" do
        %w[SP RJ MG RS].each do |uf|
          expect(build(:loan, state_code: uf)).to be_valid
        end
      end

      it "rejeita UF inexistente" do
        loan = build(:loan, state_code: "XX")
        expect(loan).not_to be_valid
        expect(loan.errors[:state_code]).to include("XX não é uma UF válida")
      end

      it "rejeita UF em branco" do
        loan = build(:loan, state_code: "")
        expect(loan).not_to be_valid
      end
    end
  end

  describe "scopes" do
    let!(:active_loan)    { create(:loan, state_code: "SP", status: "active") }
    let!(:cancelled_loan) { create(:loan, state_code: "SP", status: "cancelled") }
    let!(:rj_loan)        { create(:loan, state_code: "RJ", status: "active") }

    describe ".active" do
      it "retorna apenas empréstimos ativos" do
        expect(Loan.active).to include(active_loan, rj_loan)
        expect(Loan.active).not_to include(cancelled_loan)
      end
    end

    describe ".by_state" do
      it "filtra por estado" do
        expect(Loan.by_state("SP")).to include(active_loan)
        expect(Loan.by_state("SP")).not_to include(rj_loan)
      end
    end
  end

  describe "#cancel!" do
    it "cancela um empréstimo ativo" do
      loan = create(:loan, status: "active")
      loan.cancel!
      expect(loan.reload).to be_cancelled
    end

    it "levanta erro ao cancelar empréstimo já cancelado" do
      loan = create(:loan, status: "cancelled")
      expect { loan.cancel! }.to raise_error(Loan::AlreadyCancelledError)
    end
  end
end
