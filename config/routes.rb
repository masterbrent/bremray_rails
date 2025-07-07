Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
  
  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication
      post 'auth/login', to: 'auth#login'
      post 'auth/refresh', to: 'auth#refresh'
      
      # Job Cards (Tech endpoints)
      resources :job_cards, only: [:index, :show] do
        member do
          patch 'increment_item'
          post 'custom_entries', action: :create_custom_entry
          post 'close'
          post 'reopen'
        end
      end
      
      # Photos
      resources :jobs, only: [] do
        resources :photos, only: [:index, :create, :destroy] do
          member do
            get 'download'
          end
        end
      end
      
      # Other routes will be added as controllers are created with tests
    end
  end
end
