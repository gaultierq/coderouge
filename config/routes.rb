Rails.application.routes.draw do
  resources :waypoints do
    collection do
      get 'polyline'
    end

  end

  resources :stopovers

  root 'waypoints#index'



end
