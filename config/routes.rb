Rails.application.routes.draw do
  resources :waypoints do
    collection do
      get 'polyline'
    end

  end

  root 'waypoints#index'



end
