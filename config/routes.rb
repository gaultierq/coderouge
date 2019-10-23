Rails.application.routes.draw do

  resources :waypoints do
    collection do
      get 'polyline'
    end
    member do
      get 'last_position'
    end


  end


  resources :stopovers

  root 'waypoints#index'
  get 'infos' => 'waypoints#infos'

end
