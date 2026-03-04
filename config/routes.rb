Rails.application.routes.draw do
  if Rails.env.development?
    mount Lookbook::Engine, at: "/lookbook"
  end

  root to: "dashboard#index"
  devise_for :users

  # get "expenses/splits_fields", to: "expenses#expense_splits_fields", as: :expense_splits_fields

  resources :dashboard, only: :index
  resources :exchange_rates, only: :index
  resources :money_accounts, except: :edit do
    resources :incomings
    resources :transfers, except: :destroy
  end

  resources :transfers, only: :destroy

  resources :item_prices, only: %i[index destroy] do
    get :barcode_reader, on: :collection
    resources :store_items, only: %i[edit update]
  end
  resources :store_items, except: %i[index edit destroy] do
    get :store_fields, on: :collection
  end
  resources :expenses
  resources :incomings, except: %i[new create]
  resources :budgets, except: :edit
  resources :transaction_groups do
    member do
      patch :add_expense
    end
  end

  resources :transactions_reports, only: %i[index new create show destroy] do
    resource :download, only: :show, module: :transactions_reports
  end
end
