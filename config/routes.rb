Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  resources :transactions, only: [:new, :create, :edit, :update]
  resource :off_skin_balance, only: [:edit, :update], controller: 'off_skin_balance'
  resources :hourly_sents, only: [:index] do
    member do
      patch :mark_as_viewed
    end
  end
  resources :biddeds, only: [:index]
  resources :snipes
  resources :targets, controller: 'targets'
  resources :search_items, only: [:index] do
    collection do
      get :fade
      get :blue_gem
      get :low_float
      get :keychain
      get :gloves
      patch :mark_item_as_viewed
    end
  end

  root to: "home#index"
  # Defines the root path route ("/")
  # root "posts#index"
end
