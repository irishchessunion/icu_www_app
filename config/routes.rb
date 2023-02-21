IcuWwwApp::Application.routes.draw do
  root to: "pages#home"

  get  "sign_in"  => "sessions#new"
  get  "sign_out" => "sessions#destroy"
  get  "sign_up"  => "users#new"
  get  "redirect" => "redirects#redirect"
  get  "header"   => "header#control"

  %w[home home2 links juniors beginners for_parents primary_schools secondary_schools].each do |page|
    get page => "pages##{page}"
  end
  %w[clubs events].each do |page|
    get "maps/#{page}(/:id)" => "maps##{page}", as: "#{page}_map"
  end
  %w[shop cart card charge confirm completed new_payment_error].each do |page|
    match page => "payments##{page}", via: page == "charge" || page == "new_payment_error" ? :post : :get
  end
  %w[account preferences update_preferences].each do |page|
    match "#{page}/:id" => "users##{page}", via: page.match(/^update/) ? :post : :get, as: page
  end
  (Global::ICU_PAGES + Global::ICU_DOCS.keys).each do |page|
    get "icu/#{page}" => "icu##{page}"
  end
  Global::HELP_PAGES.each do |page|
    get "help/#{page}" => "help##{page}"
  end

  resources :articles,    only: [:index, :show] do
    get :source, on: :member
  end
  resources :likes, only: [:create, :destroy]
  resources :champions,   only: [:index, :show]
  resources :clubs,       only: [:index, :show]
  resources :documents,   only: [:index, :show, :new, :create, :edit, :update]
  resources :downloads,   only: [:index, :show]
  resources :events,      only: [:index, :show] do
    member do
      get :swiss_manager
      get :csv_list
    end
  end

  resources :games,       only: [:index, :show] do
    get :download, on: :collection
  end
  resources :images,      only: [:index, :show]
  resources :items,       only: [:new, :create, :destroy]
  resources :new_players, only: [:create]
  resources :news,        only: [:index, :show] do
    get :source, on: :member
  end
  resource :password, only: [:new, :create, :edit, :update]
  resources :player_ids,  only: [:index]
  resources :players,     only: [:index, :edit, :update]
  resources :series,      only: [:index, :show]
  resources :sessions,    only: [:create]
  resources :sponsors, only: [:index] do
    member do
      get :click_on
    end
  end
  resources :tournaments, only: [:index, :show]
  resources :users,       only: [:new, :create, :edit, :update] do
    get :verify, on: :member
  end

  namespace :admin do
    %w[session_info system_info test_email].each do |page|
      get page => "pages##{page}"
    end

    resources :articles,        only: [:new, :create, :edit, :update, :destroy]
    resources :article_ids,     only: [:index]
    resources :bad_logins,      only: [:index]
    resources :carts,           only: [:index, :show, :edit, :update] do
      get :show_intent, on: :member
    end
    resources :cash_payments,   only: [:new, :create]
    resources :champions,       only: [:new, :create, :edit, :update, :destroy]
    resources :clubs,           only: [:new, :create, :edit, :update]
    resources :downloads,       only: [:show, :new, :create, :edit, :update, :destroy]
    resources :events,          only: [:new, :create, :edit, :update, :destroy]
    resources :failures,        only: [:index, :show, :new, :update, :destroy]
    resources :fees do
      get :rollover, :clone, on: :member
    end
    resources :games,           only: [:edit, :update, :destroy]
    resources :images,          only: [:new, :create, :edit, :update, :destroy]
    resources :items,           only: [:index, :edit, :update] do
      get :sales_ledger, on: :collection
    end
    resources :junior_newsletters, only: [:index]
    resources :journal_entries, only: [:index, :show]
    resources :logins,          only: [:index, :show]
    resources :mail_events,     only: [:index]
    resources :news,            only: [:new, :create, :edit, :update, :destroy]
    resources :officers,        only: [:index, :show, :edit, :update]
    resources :payment_errors,  only: [:index]
    resources :pgns
    resources :players,         only: [:show, :new, :create, :edit, :update]
    resources :refunds,         only: [:index]
    resources :relays,          only: [:index, :show, :edit, :update] do
      get :refresh, :enable_all, :disable_all, on: :collection
    end
    resources :results, except: [:show] do
      member do
        post :ban
      end
    end

    resources :series,          only: [:new, :create, :edit, :update, :destroy]
    resources :sponsors, only: [:new, :create, :edit, :update, :show]
    resources :statistics, only: [:index]
    resources :tournaments,     only: [:new, :create, :edit, :update, :destroy]
    resources :translations,    only: [:index, :show, :edit, :update, :destroy]
    resources :user_inputs,     only: [:show, :new, :create, :edit, :update, :destroy]
    resources :users do
      get :login, on: :member
    end
  end

  match "*url", to: "pages#not_found", via: :all
end
