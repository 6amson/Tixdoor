Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  post '/signup', to: 'users#signup'
  post '/signin', to: 'users#signin'
  delete '/signout', to: 'users#signout'
  
  resources :complaints, only: [:create, :show, :index] do
    member do
      post :add_comment
      patch :update_status
    end
  end
end
