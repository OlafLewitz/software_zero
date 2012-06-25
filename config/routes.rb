require File.expand_path("../lib/env", File.dirname(__FILE__))

OpenYourProject::Application.routes.draw do

  resources :pages, :only => Env['CREATE_PAGES'] ? %w[ new create edit update index ] : %w[ index ]

  root :to => Env['CREATE_PAGES'] ? 'pages#new' : 'pages#index'

  match ':slug' => 'pages#show', :constraints => /^[^\s\/<>+]+$/

end
