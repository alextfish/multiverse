Multiverse::Application.routes.draw do

  # You can have the root of your site routed with 'root'
  # just remember to delete public/index.html.
  root :to => 'pages#home'
  # also defines root_path => '/' and root_url  => 'http://localhost:3000/'

  get '/contact', :to => 'pages#contact'
  # also defines contact_path => '/contact' and contact_url => 'http://localhost:3000/contact'
  get '/about',   :to => 'pages#about'
  get '/help',    :to => 'pages#help'
  get '/news',    :to => 'pages#news'
  get '/spam',    :to => 'pages#spam'
  get '/random',    :to => 'pages#random'
  get '/card_back', :to => 'pages#card_back'

  get 'pages/home'

  resources :old_cards, :only => [:create, :destroy]

  resources :comments, :only => [:create, :destroy, :edit, :update]

  resources :cards, :only => [:new, :create, :destroy, :edit, :update, :show]
  resources :cards do
    member do
      get 'move'
      put 'process_move'
      get 'mockup'
    end
  end

  # The cards/cardsets relation should probably be a nested resource.
  # This would provide cardset_cards_path(@cardset), etc.
  # But I don't want the faff of refactoring to deal with that, so instead I'll create my own route:
  resources :cardsets do
    resources :details_pages, :only => [:new, :create, :destroy, :edit, :update, :show]
    resources :mechanics,     :only => [:new, :create, :destroy, :edit, :update, :index]
    resources :decklists,     :only => [:new, :index]
    resources :comments,      :only => [:new, :create, :destroy, :edit, :update, :index]
    member do
      get 'cardlist' # in addition to /cardsets/:id which goes to cardsets#show
      get 'visualspoiler', 'wholevisualspoiler', 'recent'
      get 'import', 'export', 'plaintext', 'csv'
      get 'todo', 'booster', 'comments'
      get 'skeleton'
      post 'import_data', 'generate_skeleton'
    end
  end


  resources :users do
    resources :decklists
  end

  resources :sessions, :only => [:new, :create, :destroy]

  #get 'sessions/new'
  get '/signup',  :to => 'users#new'
  get '/signin',  :to => 'sessions#new'
  get '/signout', :to => 'sessions#destroy'
  get '/profile', :to => 'users#show'

  resources :searches, :only => [:advanced, :do_search, :do_quicksearch, :show]

  get '/advanced_search', :to => 'searches#advanced'
  post '/quicksearch',    :to => 'searches#do_quicksearch'
  match '/search',        :to => 'searches#do_search', via: [:get, :post]

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # See how all your routes lay out with 'rake routes'

end
