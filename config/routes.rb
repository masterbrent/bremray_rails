Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
  
  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication
      post 'auth/login', to: 'auth#login'
      post 'auth/refresh', to: 'auth#refresh'
      
      # Other routes will be added as controllers are created with tests
    end
  end
end
