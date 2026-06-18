Rails.application.routes.draw do
  scope :loans do
    get 'concentration', to: 'loans#concentration'
  end

  resources :loans, only: %i[index show create]

  get '/up', to: proc { [200, {}, [{ status: 'ok' }.to_json]] }
end
