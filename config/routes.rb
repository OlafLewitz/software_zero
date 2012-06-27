require File.expand_path("../lib/env", File.dirname(__FILE__))

OpenYourProject::Application.routes.draw do

  root :to => Env['CREATE_PAGES'] ? 'pages#new' : 'collections#index'

  resources :collections, :only => %w[ index ]
  resources :pages, :only => %w[ new create edit update index ] if Env['CREATE_PAGES']

  match ':slug' => 'pages#show', :constraints => /^[^\s\/<>+]+$/

end
