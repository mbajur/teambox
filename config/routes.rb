Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  resources :sites, only: [ :show, :new, :create ]

  get "/public" => "public/projects#index", :as => :public_projects
  get "/goodbye" => "static_pages#goodbye", :as => :goodbye

  namespace :public do
    get ":id" => "projects#show", :as => :project
    get ":project_id/conversations" => "conversations#index", :as => :project_conversations
    get ":project_id/conversations/:id" => "conversations#show", :as => :project_conversation
    get ":project_id/:id" => "pages#show", :as => :project_page
  end

  get "api" => "apidocs#index", :as => :api
  get "api/concepts" => "apidocs#concepts", :as => :api_concepts
  get "api/routes" => "apidocs#routes", :as => :api_routes
  get "api/auth" => "apidocs#auth", :as => :api_auth
  get "api/changes" => "apidocs#changes", :as => :api_changes
  get "api/:model" => "apidocs#model", :as => :api_model

  resources :sprockets, only: [ :index, :show ]

  get "/logout" => "sessions#destroy", :as => :logout
  get "/login" => "sessions#new", :as => :login
  get "/login/:username" => "sessions#backdoor", :as => :login_backdoor if Rails.env.test?

  get "/register" => "users#create", :as => :register
  get "/signup" => "users#new", :as => :signup

  get "/search" => "search#index", :as => :search

  get "/guides" => "guides#index", :as => :guides

  get "/text_styles" => "users#text_styles", :as => :text_styles
  get "/email_posts_path" => "users#email_posts", :as => :email_posts
  get "/invite_format" => "invitations#invite_format", :as => :invite_format
  get "/feeds" => "users#feeds", :as => :feeds
  get "/calendars" => "users#calendars", :as => :calendars
  get "/disable_splash" => "users#disable_splash", :as => :disable_splash
  get "/forgot" => "reset_passwords#new", :as => :forgot_password
  get "/reset/:reset_code" => "reset_passwords#reset", :as => :reset_password
  get "/forgetting" => "reset_passwords#update_after_forgetting", :as => :update_after_forgetting, :method => :put
  get "/reset_password_sent" => "reset_passwords#sent", :as => :sent_password

  get "/format/:f" => "sessions#change_format", :as => :change_format

  get "/projects/:project_id/invite/:login" => "invitations#create", :as => :create_project_invitation, :method => :post

  get "/auth/:provider/callback" => "auth#callback", :as => :auth_callback
  get "/auth/failure" => "auth#failure", :as => :auth_failure
  get "/complete_signup" => "users#complete_signup", :as => :complete_signup
  get "/auth/:provider/unlink" => "users#unlink_app", :as => :unlink_app

  resources :google_docs do
    get :search, on: :collection
  end

  resources :google_calendars

  # RAILS 3 Useless resource?
  resources :reset_passwords
  resource :session

  resources :organizations do
    member do
      get :projects
      get :external_view
      get :delete
      get :appearance
      patch :update_appearance
    end
    resources :memberships do
      member do
        get :change_role
        get :add
        get :remove
      end
    end
    resources :task_list_templates do
      collection do
        put :reorder
      end
    end
  end

  get "/account/settings" => "users#edit", :as => :account_settings, :sub_action => "settings"
  get "/account/picture" => "users#edit", :as => :account_picture, :sub_action => "picture"
  get "/account/profile" => "users#edit", :as => :account_profile, :sub_action => "profile"
  get "/account/linked_accounts" => "users#edit", :as => :account_linked_accounts, :sub_action => "linked_accounts"
  get "/account/notifications" => "users#edit", :as => :account_notifications, :sub_action => "notifications"
  get "/account/delete" => "users#edit", :as => :account_delete, :sub_action => "delete"
  get "/account/destroy" => "users#destroy", :as => :destroy_user
  get "/account/activity_feed_mode/collapsed" => "users#change_activities_mode", :as => :collapse_activities, :collapsed => true
  post "/account/activity_feed_mode/expanded" => "users#change_activities_mode", :as => :expand_activities, :collapsed => false
  get "/account/watch_list" => "watchers#index", :as => :watch_list
  post  "/account/watch_list/unwatch/:watch_id" => "watchers#unwatch", :as => :unwatch
  post  "/account/stats/:stat/inc" => "users#increment_stat"
  post  "/account/badge/:badge/grant" => "users#grant_badge"
  post  "/account/first_steps/hide" => "users#hide_first_steps"

  resources :teambox_datas, path: "/datas" do
    member do
      get :download
    end
  end

  resources :users do
    resources :invitations
    member do
      get :confirm_email
      get :unconfirmed_email
      get :contact_importer
    end
    resources :conversations
    resources :task_lists do
      resources :tasks
    end
    get "activities/users/:id/show_more(.:format)" => "activities#show_more", :as => :show_more, :method => :get
  end

  get "activities(.:format)" => "activities#show", :as => :activities, :method => :get
  get "activities/:id/show_more(.:format)" => "activities#show_more", :as => :show_more, :method => :get
  get "activities/:id/show_thread(.:format)" => "activities#show_thread", :as => :show_thread, :method => :get

  get "projects/archived.:format" => "projects#index", :as => :project_archived, :sub_action => "archived"

  get "hooks/:hook_name" => "hooks#create", :as => :hooks, :via => :post

  resources :projects do
    member do
      post :accept
      post :decline
      get :join
    end

    get "time/:year/:month" => "hours#index", :as => :hours_by_month, :via => :get
    get "time/by_period" => "hours#by_period", :as => :hours_by_period, :via => :get
    get "time" => "hours#index", :as => :time
    get "settings" => "projects#edit", :as => :settings, :sub_action => "settings"
    get "picture" => "projects#edit", :as => :picture, :sub_action => "picture"
    get "deletion" => "projects#edit", :as => :deletion, :sub_action => "deletion"
    get "ownership" => "projects#edit", :as => :ownership, :sub_action => "ownership"

    resources :invitations do
      member do
        put :accept
        put :decline
        get :resend
      end
    end

    get "activities(.:format)" => "activities#show", :as => :activities, :method => :get
    get "activities/:id/show_more(.:format)" => "activities#show_more", :as => :show_more, :method => :get

    get "move/:id" => "uploads#move", :via => :put, :as => :move_resource

    resources :uploads do
      member do
        get :public_download
        put :rename
      end
      collection do
        resources :folders, except: [ :show, :index, :new ] do
          member do
            get :public_download, controller: "uploads", action: "public_download"
            put :rename
          end
        end
      end
    end

    get "downloadable/:id/email_public" => "uploads#email_public", :via => :post, :as => :email_public_download

    get "uploads/folders/:id" => "uploads#index", :via => :get
    get "hooks/:hook_name" => "hooks#create", :as => :hooks, :via => :post

    match "invite_people" => "projects#invite_people", :as => :invite_people, :via => :get
    match "invite_people" => "projects#send_invites", :as => :send_invites, :via => :post

    resources :tasks do
      member do
        put :reorder
        put :watch
        put :unwatch
      end

      resources :comments
    end

    resources :task_lists do
      collection do
        get :gantt_view
        get :archived
        put :reorder
      end
      member do
        put :archive
        put :unarchive
        put :watch
        put :unwatch
      end

      resources :tasks do
        member do
          put :watch
          put :unwatch
        end

        resources :comments
      end
    end

    get "contacts" => "people#contacts", :as => :contacts, :method => :get

    resources :people do
      member do
        get :destroy
      end
    end

    resources :conversations do
      member do
        patch :convert_to_task
        put :watch
        put :unwatch
      end

      resources :comments
    end

    resources :pages do
      collection do
        post :resort
      end
      member do
        post :reorder
        put :watch
        put :unwatch
      end
      # In rails 2, we have :pages, :has_many => :task_list ?!
      resources :notes, :dividers, :uploads
    end

    get "search" => "search#index", :as => :search

    resources :google_docs do
      collection do
        :search
      end
      member do
        put :write_access, path: "write_access/:access", access: /lock|unlock/
      end
    end
  end

  namespace :api_v1, path: "api/1" do
    resources :app_links, except: [ :edit, :update ]
    resources :projects, except: [ :new, :edit ] do
      resources :activities, only: [ :index, :show ]

      resources :people, except: [ :create, :new, :edit ]

      resources :comments, except: [ :new, :create, :edit ]

      resources :conversations, except: [ :new, :edit ] do
        member do
          put :watch
          put :unwatch
          post :convert_to_task
        end

        resources :comments, except: [ :new, :edit ]
      end

      resources :invitations, except: [ :new, :edit, :update ] do
        member do
          put :resend
        end
      end

      resources :task_lists, except: [ :new, :edit ] do
        member do
          put :archive
          put :unarchive
        end
        collection do
          put :reorder
        end

        resources :tasks, except: [ :new, :edit ]
      end

      resources :tasks, except: [ :new, :edit ] do
        member do
          put :watch
          put :unwatch
          put :reorder
        end

        resources :comments, except: [ :new, :edit ]
      end

      resources :uploads, except: [ :new, :edit, :update ]

      resources :pages, except: [ :new, :edit ] do
        collection do
          put :resort
        end

        member do
          put :reorder
          put :watch
          put :unwatch
        end
      end

      resources :notes, except: [ :new, :edit ]

      resources :dividers, except: [ :new, :edit ]

      get "search" => "search#index", :as => :search
    end

    resources :activities, only: [ :index, :show ]

    resources :invitations, except: [ :new, :edit, :update, :create ] do
      member do
        put :accept
      end
    end

    resources :users, except: [ :new, :edit ]

    resources :tasks, except: [ :new, :edit, :create ] do
      member do
        put :watch
        put :unwatch
      end
    end

    resources :comments, except: [ :new, :create, :edit ]

    resources :conversations, except: [ :new, :edit ] do
      member do
        put :watch
        put :unwatch
      end

      resources :comments, except: [ :new, :edit ]
    end

    resources :task_lists, except: [ :new, :edit ] do
      resources :tasks, except: [ :new, :edit ]
    end

    resources :tasks, except: [ :new, :edit, :create ] do
      member do
        put :watch
        put :unwatch
      end

      resources :comments, except: [ :new, :edit ]
    end

    resources :uploads, except: [ :new, :edit, :update ]
    resources :pages, except: [ :new, :edit ] do
      collection do
        put :resort
      end
      member do
        put :reorder
        put :watch
        put :unwatch
      end
    end

    resources :notes, except: [ :new, :edit ]

    resources :dividers, except: [ :new, :edit ]

    resources :organizations, except: [ :new, :edit, :destroy ] do
      resources :projects, except: [ :new, :edit ] do
      end

      resources :memberships, except: [ :new, :edit, :create ]
    end
    get "search" => "search#index", :as => :search
    get "account" => "users#current", :as => :account, :via => :get
  end

  resources :task_lists, only: [ :index ] do
    collection do
      get :gantt_view
    end
  end

  resources :conversations, only: [ :create ]

  get "time/:year/:month" => "hours#index", :as => :hours_by_month, :via => :get
  get "time/by_period" => "hours#by_period", :as => :hours_by_period, :via => :get
  get "time" => "hours#index", :as => :time

  get "/my_projects" => "projects#list", :as => :all_projects

  get "downloads/:id(/:style)/:filename" => "uploads#download", :constraints => { filename: /.*/ }, :via => :get

  get "f/:token" => "public_downloads#folder", :via => :get, :as => :public_download_folder
  get "d/:token" => "public_downloads#download", :via => :get, :as => :public_download_file
  get "send/:token" => "public_downloads#download_send", :via => :get, :as => :public_send_file

  root to: "projects#index"

  # if Rails.env.development?
  #   mount Emailer::Preview => "mail_view"
  # end

  if Rails.env.test?
    get "/oauth/dummy_auth" => "oauth#dummy_auth", :as => :dummy_auth
  end

  # Oauth provider
  # Oauth-server

  get "/oauth", controller: "oauth", action: "index", as: :oauth
  get "/oauth/authorize", controller: "oauth", action: "authorize", as: :authorize
  get "/oauth/revoke", controller: "oauth", action: "revoke", as: :revoke
  get "/oauth/token", controller: "oauth", action: "token", as: :token

  resources :oauth_clients do
    collection do
      get :developer
    end
  end

  get "trimmer/:locale/templates.js" => "trimmer#templates", :as => :trimmer_templates
  get "trimmer/:locale/translations.js" => "trimmer#translations", :as => :trimmer_translations
  get "trimmer/:locale.js" => "trimmer#resources", :as => :trimmer_resources
end
