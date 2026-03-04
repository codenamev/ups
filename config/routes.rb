Rails.application.routes.draw do
  # Unsubscribe routes
  get "unsubscribe/:token", to: "unsubscribe#show", as: :unsubscribe
  post "unsubscribe/:token", to: "unsubscribe#confirm", as: :unsubscribe_confirm
  
  # MCP (Model Context Protocol) server endpoint — powered by ActionMCP
  mount ActionMCP::Engine => "/mcp"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication routes
  resources :sessions, only: [ :new, :create, :destroy ]
  get "auth/magic_link", to: "sessions#verify_magic_link", as: :verify_magic_link
  delete "sign_out", to: "sessions#destroy", as: :sign_out

  # Registration routes
  resources :registrations, only: [ :new, :create ]
  get "sign_up", to: "registrations#new"
  get "register", to: "registrations#new"

  # Convenience routes
  get "sign_in", to: "sessions#new"
  get "login", to: "sessions#new"

  # API routes with token authentication
  namespace :api do
    namespace :v1 do
      # Discovery endpoint (no auth required)
      get "/", to: "discovery#show"
      resources :status_pages, except: [ :new, :edit ] do
        resources :webhooks, except: [ :new, :edit ]
        resources :components, except: [ :new, :edit ]
        resources :incidents, except: [ :new, :edit ] do
          resources :updates, controller: "incident_updates", except: [ :new, :edit ]
        end
        resources :subscribers, only: [ :index, :create, :destroy ]
      end

      resources :api_tokens, only: [ :index, :create, :destroy ]
      get "profile", to: "users#show"
    end
  end

  # Dashboard routes (authenticated web interface)
  scope "/dashboard" do
    get "/", to: "dashboard#index", as: :dashboard

    resources :status_pages do
      resources :components
      resources :incidents do
        resources :incident_updates
      end
      resources :monitors
      resources :subscribers
    end

    resources :api_tokens, except: [ :show ]
    resource :profile, only: [ :show, :edit, :update ]
    resources :accounts, only: [ :index, :show, :new, :create, :edit, :update ]
  end

  # SEO routes (must come before catchall status page routes)
  get "sitemap.xml", to: "sitemaps#index", defaults: { format: :xml }

  # Public status pages (no authentication required)
  get ":slug", to: "public/status_pages#show", as: :public_status_page, constraints: { slug: /[a-z0-9\-]+/ }
  get ":slug.json", to: "public/status_pages#show", defaults: { format: :json }
  get ":slug/incidents.json", to: "public/incidents#index", defaults: { format: :json }
  get ":slug/components.json", to: "public/components#index", defaults: { format: :json }

  # Public subscriptions
  post ":slug/subscribe", to: "public/subscribers#create", as: :public_subscribe, constraints: { slug: /[a-z0-9\-]+/ }
  get ":slug/unsubscribe/:token", to: "public/subscribers#destroy", as: :public_unsubscribe, constraints: { slug: /[a-z0-9\-]+/ }

  # Root redirect
  root "pages#home"
end
