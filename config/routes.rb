OpenYourProject::Application.routes.draw do

  resources :pages, :only => Env['CREATE_PAGES'] ? %w[ new create index ] : %w[ index ]

  root :to => Env['CREATE_PAGES'] ? 'pages#new' : 'pages#index'

end
