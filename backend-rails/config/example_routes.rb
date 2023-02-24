Rails.application.routes.draw do
  require 'sidekiq/web'
  require 'sidekiq/cron/web'

  mount Sidekiq::Web => '/sidekiq'
  mount Searchjoy::Engine, at: "searchjoy"

  namespace :oauth do
    match :create_omniouth, controller: :zoho_oauth, via: [:get, :post]
  end

  api_version module: 'v1', header: { name: 'API-VERSION', value: 'v1' } do
    namespace :ionic do
      resources :auctions do
        resources :lots, only: [:index, :create]
      end

      get :lot_meta_deta, controller: :lots, action: :meta_deta
    end

    namespace :admin do
      resources :customer_payments, only: [:create]
      resources :countries, only: [:index]
      resources :warehouses do
        member do
            get :in_stock
        end
      end
      resources :feedbacks

      resource :dashboard, controller: :dashboard, only: [] do
        collection do
          get :active
          get :closed
          get :moderation
        end
      end

      resources :communities, only: [:index]
      resources :assignments, only: [:index]

      get :lots_with_highest_bid, controller: :lots

      resources :purchase_invoice_credit_notes
      resources :purchase_invoices
      resources :sales_invoice_credit_notes
      resources :sales_invoices
      resources :payment_requests, only: [:index, :show] do
        member do
          get :download
        end

        collection do
          get :delivered
        end
      end

      resources :credit_notes

      resources :categories, only: [:index, :create, :show, :update]

      resources :category_fields do
        get :autocomplete, on: :collection
      end

      resources :category_field_values do
        collection do
          get :fetch
        end
      end

      resources :auctions do
        get :autocomplete, on: :collection

        resources :lots do

          collection do
            get :export_for_csv
          end

          resources :assignments

          collection do
            get :export_for_csv
          end

          resources :bids do
            collection do
              delete :destroy_all
            end
          end
        end
      end

      resources :seller_entity do
        get :autocomplete, on: :collection
      end

      resources :buyer_entity do
        get :autocomplete, on: :collection
      end

      resources :users do
        resources :lots, controller: 'lots_for_user', only: [] do
          collection do
            get :bids_on
            get :won
            get :lost
            get :selling
          end
        end

        resources :bids, controller: 'bids_for_user'
        resources :notifications, only: [:index]
        resources :assignments, controller: :assignments_for_user, only: [:index]
        resources :payment_requests, controller: :payment_requests_for_user, only: [:index] do
        end

        get :profile, on: :collection
      end

      resources :companies
      resources :web_pages

      resources :assignments, only: [] do
        collection do
          post :assign
          post :add_signature
          get :goods_handover
        end
      end

      resources :miscellaneous, only: [] do
        collection do
          post :zip_bulk_upload
        end
      end

      resources :lots, only: [] do
        collection do
          get :with_no_warehouse
          post :receive_with_signature
        end
      end
    end

    resources :feedbacks, only: [:index] do
      collection do
        get 'fetch/:user_type', action: :fetch
      end
    end

    resources :feedback_submissions
    resources :purchase_invoice_credit_notes
    resources :purchase_invoices
    resources :sales_invoice_credit_notes
    resources :sales_invoices

    resources :payment_requests, controller: :payment_requests_for_user, only: [:index] do
      end

    resources :categories, only: [:index, :create, :show, :update]

    resources :category_fields do
      get :autocomplete, on: :collection
    end

    resources :category_field_values do
      collection do
        get :fetch
      end
    end

    resources :auctions do
      collection do
        get :autocomplete
        get :closing
      end

      resources :lots do
        member do
          get :winning_bids
          get :is_winner
        end

        collection do
          get :subscribed_lots
        end

        resources :assignments

        resources :bids do
          collection do
            delete :destroy_all
          end
        end
      end
    end

    resources :seller_entity do
      get :autocomplete, on: :collection
    end

    resources :buyer_entity do
      get :autocomplete, on: :collection
    end

    resources :users do
      member do
        get :dashboard_counts
      end

      resources :lots, controller: 'lots_for_user', only: [:index] do
        collection do
          get :bids_on
          get :won
          get :lost
          get :selling
          get :negotation
        end
      end

      resources :bids, controller: 'bids_for_user'
      resources :notifications, only: [:index] do
        collection do
          get :unseen
        end
      end

      get :profile, on: :collection
    end

    resources :companies
    resources :web_pages

    resources :assignments, only: [] do
      collection do
        post :assign
      end
    end

    resources :miscellaneous, only: [] do
      collection do
        post :zip_bulk_upload
      end
    end

    resources :notification_preferences, only: [:index] do
      collection do
        put :bulk_update
      end
    end

    get 'sitemap.xml', to: 'miscellaneous#sitemap', format: :xml
  end
end
