Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with 'rake routes'.

  root 'home#index'

  devise_for :users

  get 'gc', controller: :home

  scope '/plaques' do
    resource :latest, as: :latest, controller: :plaques_latest, only: :show
  end

  resources :plaques do
    member do
      post 'flickr_search'
      get 'flickr_search_all'
    end
    resource :location, controller: :plaque_location, only: :edit
    resource :series, controller: :plaque_series, only: :edit
    resource :colour, controller: :plaque_colour, only: :edit
    resource :geolocation, controller: :plaque_geolocation, only: :edit
    resource :inscription, controller: :plaque_inscription, only: :edit
    resource :description, controller: :plaque_description, only: [:edit, :show]
    resource :language, controller: :plaque_language, only: :edit
    resources :connections, controller: :personal_connections, as: :connections
    resource :photos, controller: :plaque_photos, only: :show
    resource :talk, controller: :plaque_talk, only: :create
    resources :sponsorships
  end
  # map tiles are numbered using the convention at http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames
  match 'plaques/tiles/:zoom/:x/:y' => 'plaques#index', constraints: { zoom: /\d{2}/, x: /\d+/, y: /\d+/ }, via: [:get]
  match 'plaques/unphotographed/tiles/:zoom/:x/:y' => 'plaques#index', id: 'unphotographed', constraints: { zoom: /\d{2}/, x: /\d+/, y: /\d+/ }, via: [:get]

  resources :places, controller: :countries, as: :countries do
    collection do
      get 'autocomplete', controller: :areas
    end
    resource :plaques, controller: :country_plaques, only: :show
    resources :areas do
      resource :plaques, controller: :area_plaques, only: :show
      match 'plaques/:filter' => 'area_plaques#show', via: [:get]
    end
  end

  resources :photos
  resources :photographers, as: :photographers, only: [:create, :index, :show, :new]
  resources :licences, only: [:index, :show]

  resources :organisations do
    collection do
      get 'autocomplete'
    end
    resource :plaques, controller: :organisation_plaques, only: :show
    match 'plaques/tiles/:zoom/:x/:y' => 'organisation_plaques#show', constraints: { zoom: /\d{2}/, x: /\d+/, y: /\d+/ }, via: [:get]
    match 'plaques/:filter' => 'organisation_plaques#show', via: [:get]
  end

  scope '/unveilings' do
    resource :upcoming, only: [:show], controller: :upcoming_unveilings
  end

  resources :verbs, only: [:create, :index, :show, :new] do
    collection do
      get 'autocomplete'
    end
  end

  scope '/roles' do
    resources 'a-z', controller: :roles_by_index, as: 'roles_by_index', only: [:show, :index]
  end
  resources :roles do
    collection do
      get 'autocomplete'
    end
  end
  resources :personal_roles

  scope '/people' do
    resources 'a-z', controller: :people_by_index, as: 'people_by_index', only: :show
    resources :born_on, controller: :people_born_on, as: 'people_born_on', only: [:index, :show]
    resources :died_on, controller: :people_died_on, as: 'people_died_on', only: [:index, :show]
    resources :born_in, controller: :people_born_on, as: 'people_born_in', only: [:index, :show]
    resources :died_in, controller: :people_died_on, as: 'people_died_in', only: [:index, :show]
    resources :alive_in, controller: :people_alive_in, as: 'people_alive_in', only: [:index, :show]
  end
  resources :people do
    collection do
      get 'autocomplete'
    end
    resource :plaques, controller: :person_plaques, only: :show
    resource :roles, controller: :person_roles, only: :show
  end

  resources :languages
  resources :colours, only: [:index, :new, :create]
  resources :series do
    resource :plaques, controller: :series_plaques, only: :show
    match 'plaques/tiles/:zoom/:x/:y' => 'series_plaques#show', constraints: { zoom: /\d{2}/, x: /\d+/, y: /\d+/ }, via: [:get]
  end
  resources :todo
  resources :picks

  # Convenience paths for search:
  match 'search' => 'search#index', via: [:get]
  match 'search/:phrase' => 'search#index', via: [:get]
  match 'match' => 'match#index', via: [:get]

  # Convenience resources for important pages:
  resources :pages
  resource :about, controller: :pages, id: 'about', only: :show
  resource :contact, controller: :pages, id: 'contact', only: :show
  scope '/about' do
    resource :data, controller: :pages, id: 'data', as: 'about_the_data', only: :show
  end
  resource :contribute, controller: :pages, id: 'contribute', as: 'contribute', only: :show
  resource :explore, controller: :explore, only: :show

end
