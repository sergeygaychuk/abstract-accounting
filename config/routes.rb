Abstract::Application.routes.draw do
  devise_for :users

  resources :users do
    collection do
      get 'view'
    end
  end
  resources :roles do
    collection do
      get 'view'
    end
  end
  resources :entities do
    collection do
      get 'view'
    end
  end
  resources :entity_reals do
    collection do
      get 'view'
    end
  end
  resources :resources do
    member do
      get 'edit_asset'
      get 'edit_money'
      put 'update_asset'
      put 'update_money'
    end
    collection do
      get 'new_asset'
      get 'new_money'
      post 'create_asset'
      post 'create_money'
      get 'view'
    end
  end
  resources :deals do
    collection do
      get 'view'
    end
  end
  resources :facts
  resources :charts
  resources :quotes do
    collection do
      get 'view'
    end
  end
  resources :balances do
    collection do
      get 'load'
      get 'total'
    end
  end
  resources :general_ledgers do
    collection do
      get 'view'
    end
  end
  resources :transcripts do
    collection do
      get 'load'
    end
  end
  resources :rules do
    collection do
      get 'view'
      get 'data'
    end
  end
  resources :waybills do
    collection do
      get 'view'
    end
  end
  resources :storehouses do
    collection do
      get 'view'
      get 'releases'
      get 'list'
      get 'view_release'
      get 'pdf'
      post 'cancel'
      post 'apply'
      get 'waybill_list'
      get 'return'
      get 'return_list'
      get 'return_resources'
      get 'resource_state'
    end
    member do
      get 'waybill_entries_list'
    end
  end
  resources :places do
    collection do
      get 'view'
    end
  end
  resources :home do
    collection do
      get 'main'
    end
  end
  #get "home/index"

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)
  match 'entities/surrogates/:real_id' => 'entities#surrogates',
        :as => :entities_surrogates
  match 'entity_reals/:real_id/surrogates(/:type)' => 'entities#select',
        :as => :entity_real_surrogates,
        :constraints => { :type => /edit/ }
  match 'entity_reals/surrogates/new' => 'entities#select'

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

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"
  root :to => "home#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
  match ':controller/releases/:action', :to => 'storehouses#create'
  match ':controller/releases/:action', :to => 'storehouses#new'
  match ':controller/releases/:action', :to => 'storehouses#list'
  match ':controller/releases/:action/:id(.:format)', :to => 'storehouses#show'
  match ':controller/releases/:action/:id(.:format)', :to => 'storehouses#cancel'
  match ':controller/releases/:action/:id(.:format)', :to => 'storehouses#apply'
  match ':controller/return/:action', :to => 'storehouses#return_list'
  match ':controller/return/:action', :to => 'storehouses#return_resources'
  match ':controller/return/:action', :to => 'storehouses#resource_state'
end
