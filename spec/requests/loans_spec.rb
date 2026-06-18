require "rails_helper"

RSpec.describe "Loans API", type: :request do
  before do
    create(:concentration_rule)           # default: 10%
    create(:concentration_rule, :for_sp)  # SP: 20%
  end

  describe "POST /loans" do
    context "empréstimo válido dentro do limite" do
      it "retorna 201 e cria o empréstimo" do
        post "/loans", params: { amount: 10_000, state_code: "MG" }

        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body["state_code"]).to eq("MG")
        expect(body["amount"]).to eq(10_000.0)
        expect(body["status"]).to eq("active")
      end
    end

    context "empréstimo que viola o limite de concentração" do
      before do
        # Carteira: 100_000 — RJ com 10_000 já está no limite de 10%
        create(:loan, state_code: "SP", amount: 90_000)
        create(:loan, state_code: "RJ", amount: 10_000)
      end

      it "retorna 422 e não cria o empréstimo" do
        expect {
          post "/loans", params: { amount: 1_000, state_code: "RJ" }
        }.not_to change(Loan, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        body = JSON.parse(response.body)
        expect(body["error"]).to include("RJ")
      end
    end

    context "UF inválida" do
      it "retorna 422" do
        post "/loans", params: { amount: 1_000, state_code: "ZZ" }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /loans" do
    before { create_list(:loan, 3, state_code: "SP") }

    it "retorna lista de empréstimos ativos" do
      get "/loans"
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.length).to eq(3)
    end
  end

  describe "GET /loans/concentration" do
    before do
      create(:loan, state_code: "SP", amount: 60_000)
      create(:loan, state_code: "RJ", amount: 30_000)
      create(:loan, state_code: "MG", amount: 10_000)
    end

    it "retorna a concentração por estado" do
      get "/loans/concentration"
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body["portfolio_total"]).to eq(100_000.0)

      sp = body["states"].find { |s| s["state"] == "SP" }
      expect(sp["concentration"]).to eq(60.0)
      expect(sp["limit"]).to eq(20.0)
      expect(sp["within_limit"]).to be false  # 60% > 20%
    end
  end
end
