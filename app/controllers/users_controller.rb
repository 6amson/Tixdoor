class UsersController < ApplicationController
  include UserAuthentication

  before_action :authenticate_user, only: [ :profile, :signout ]

  def signup
    # Rails.logger.debug("Signup params: wowowowowowowo")
    result = UserService.signup(signup_params)
    render json: result, status: :created
  rescue HttpError => e
    render_error(e)
  end

  def signin
    result = UserService.signin(params[:email], params[:password])
    render json: result, status: :ok
  rescue HttpError => e
    render_error(e)
  end

  def signout
    result = UserService.signout(current_user)
    render json: result, status: :ok
  rescue HttpError => e
    render_error(e)
  end

   def profile
    result = UserService.profile(
      user: current_user,
      page: params[:page] || 1,
      per_page: params[:per_page] || 30
    )
    render json: result
  rescue HttpError => e
    render_error(e)
  end

    def get_all_enums
    render json: UserService.get_all_enums, status: :ok
  end

  private

  def signup_params
    params.permit(:email, :password, :user_type)
  end

  def render_error(error)
    render json: {
      error: {
        message: error.message,
        status: error.status
      }
    }, status: error.status
  end
end
