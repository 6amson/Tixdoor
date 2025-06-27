Rails.application.routes.draw do
  post "/graphql", to: "graphql#execute"
  get "up" => "rails/health#show", as: :rails_health_check

  post "/signup", to: "users#signup"
  post "/signin", to: "users#signin"
  delete "/signout", to: "users#signout"
  get "/profile", to: "users#profile"
  get "/get_enums", to: "users#get_all_enums"



  resources :complaints, only: [ :create, :show, :index, :update, :destroy ] do
    member do
      post :add_comment
      patch :update_status
      delete :delete_comment
    end
  end

  # Catch-all route for unmatched paths
  match "*path", to: "application#route_not_found", via: :all
end


# Rails.application.routes.draw do
#   post "/graphql", to: "graphql#execute"
#   # mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql" if Rails.env.development?
# end
