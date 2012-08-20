require File.expand_path("../lib/env", File.dirname(__FILE__))

OpenYourProject::Application.routes.draw do

  #root :to => 'collections#index' #, :constraints => { :subdomain => /^#{SUBDOMAIN_PATTERN}/ }  # for visualizing eg a federation
  root :to => Env['ROOT_ROUTE'] || 'forked_pages#new'

  #resources :collections, :only => %w[ index ] #, :constraints => { :subdomain => /^#{SUBDOMAIN_PATTERN}/ }

  resources :pages, :only => %w[ new create edit update ] if Env['CREATE_PAGES']
  resources :forked_pages, :only => %w[ new create ]

  match 'proxy/github/*path.:format' => 'proxies#github', :as => 'github_proxy', :constraints => { :format => :json }

  match 'fake_error' => 'util#fake_error'

  if ENV['DOMAIN_CONNECTOR'].present?
    # eg http://p2pfoundation.net.via.forkthecommons.org/Unhosted
    match ':slug' => 'pages#via', :constraints => { :subdomain => /^(#{DOMAIN_SEGMENT_PATTERN}\.){2,}#{ENV['DOMAIN_CONNECTOR']}$/, :slug => %r{[^/<>+]+} }
  end
  # eg http://friendship-app.acme-behaviors-inc.appstoreforyourhead.com/friendship-app
  match ':slug' => 'pages#show', :constraints => { :subdomain => /^#{SUBDOMAIN_PATTERN}(\.#{SUBDOMAIN_PATTERN})?$/, :slug => %r{[^/<>+]+} }
end


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

# You can have the root of your site routed with "root"
# just remember to delete public/index.html.
# root :to => 'welcome#index'

# See how all your routes lay out with "rake routes"

# This is a legacy wild controller route that's not recommended for RESTful applications.
# Note: This route will make all actions in every controller accessible via GET requests.
# match ':controller(/:action(/:id))(.:format)'
