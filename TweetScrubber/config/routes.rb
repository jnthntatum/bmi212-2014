TweetScrubber::Application.routes.draw do
  devise_for :users
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
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

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end
  
  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  get 'user/' => 'users#show', as: :user_show
  get 'user/edit' => 'users#edit', as: :user_edit
  post 'user/edit' => 'users#update'

  
  # pages
  get 'user/twitter/table' => 'tweeters#table', as: :tweeters_table
  get 'user/twitter/show' => 'tweeters#show', as: :tweeters_show
  get 'user/twitter/add' => 'tweeters#add', as: :tweeters_add
  
  # api
  post 'user/twitter/loadtimeline' => 'tweeters#load_timeline', as: :tweeters_load_timeline
  post 'user/twitter/update' => 'tweeters#update_many', as: :tweeters_update_many
  post 'user/twitter/add' => 'tweeters#add_many', as: :tweeters_add_many
  post 'user/twitter/loaddescription' => 'tweeters#load_description', as: :tweeters_load_description
  
  root 'index#index'
end
