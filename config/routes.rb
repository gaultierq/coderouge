Rails.application.routes.draw do
  resources :waypoints

  root 'waypoints#index'
end
