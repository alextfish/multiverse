Multiverse::Application.routes.draw do

  # You can have the root of your site routed with 'root'
  # just remember to delete public/index.html.
  root :to => 'pages#home'
  # also defines root_path => '/' and root_url  => 'http://localhost:3000/'

  match '/contact', :to => 'pages#contact'
  # also defines contact_path => '/contact' and contact_url => 'http://localhost:3000/contact'
  match '/about',   :to => 'pages#about'
  match '/help',    :to => 'pages#help'
  match '/news',    :to => 'pages#news'

  get 'pages/home'

  get 'sessions/new'

  resources :old_cards, :only => [:create, :destroy]

  resources :comments, :only => [:create, :destroy, :edit, :update]

  resources :cards, :only => [:new, :create, :destroy, :edit, :update, :show, :move]
  resources :cards do
    member do
      get 'move'
    end
  end

  # The cards/cardsets relation should probably be a nested resource.
  # This would provide cardset_cards_path(@cardset), etc.
  # But I don't want the faff of refactoring to deal with that, so instead I'll create my own route:
  resources :cardsets do
    resources :details_pages, :only => [:new, :create, :destroy, :edit, :update, :show]
    resources :mechanics,     :only => [:new, :create, :destroy, :edit, :update, :index]
    resources :comments,      :only => [:new, :create, :destroy, :edit, :update, :index]
    member do
      get 'cardlist' # in addition to /cardsets/:id which goes to cardsets#show
      get 'visualspoiler', 'recent'
      get 'import', 'export', 'plaintext', 'csv'
      get 'todo', 'booster', 'comments'
      get 'skeleton'
      post 'import_data', 'generate_skeleton'
    end
  end


  resources :users

  resources :sessions, :only => [:new, :create, :destroy]

  match '/signup',  :to => 'users#new'
  match '/signin',  :to => 'sessions#new'
  match '/signout', :to => 'sessions#destroy'
  match '/profile', :to => 'users#show'

  resources :searches, :only => [:advanced, :do_search, :do_quicksearch, :show]

  match '/advanced_search', :to => 'searches#advanced'
  match '/search',          :to => 'searches#do_search'
  match '/quicksearch',     :to => 'searches#do_quicksearch'


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

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # See how all your routes lay out with 'rake routes'

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
