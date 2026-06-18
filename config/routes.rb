Rails.application.routes.draw do
  resources :loans, only: [:index, :show, :create] do
    collection do
      get :concentration
    end
  end

  # Health check
  get "/up", to: proc { [200, {}, [{ status: "ok" }.to_json]] }
end
