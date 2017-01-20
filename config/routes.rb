Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root 'application#root'

  # User authentication
  get '/login' => 'application#root'
  get '/logout' => 'application#logout'
  post '/login' => 'application#login_post'

  # User links
  get '/users/:username' => 'users#home'

  # Shows
  get '/shows' => 'shows#view'

  # JSON controllers (GET)
  get '/search' => 'json#search'
  get '/find_show' => 'json#find_show'


end
