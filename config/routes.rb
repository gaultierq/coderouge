Rails.application.routes.draw do
  resources :places
  get 'places/index'
  
  root 'places#index'
end
