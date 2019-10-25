Rails.application.routes.draw do

  scope path: '/waypoints', controller: :waypoints do
    get 'last_position' => :last_position
  end

  resources :waypoints do
    collection do
      get 'polyline'
    end
  end


  resources :stopovers

  root 'waypoints#index'
  get 'infos' => 'waypoints#infos'

end
