Rails.application.routes.draw do
  # get "packages/index"
  get "home/index"
  get "dashboard/index"
  post "/webhooks/17track", to: "packages#webhook_update"

  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  # root "posts#index"


  # Conditional root paths based on authentication
  authenticated :user do
    resources :packages do
      member do
        put :webhook_update
      end
    end

    # Currency converter routes
    get "currency_converter", to: "currency_converter#index"
    post "currency_converter", to: "currency_converter#convert"
    delete "currency_converter/conversions/:id", to: "currency_converter#destroy", as: :delete_currency_conversion
    delete "currency_converter/clear_history", to: "currency_converter#clear_history", as: :clear_currency_conversion_history

    # Dashboard currency converter route
    post "dashboard/convert_currency", to: "dashboard#convert_currency"

    # Remittance centers routes
    resources :places, only: [ :index ]
    resources :remittance_centers, only: [ :index, :create, :destroy ] do
      collection do
        patch :refresh
      end
    end

    root to: "dashboard#index", as: :authenticated_root
  end

  unauthenticated do
    root to: "home#index", as: :unauthenticated_root
  end

  match "*path", to: "errors#not_found", via: :all
end
