module UserAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user
  end

  private

  def authenticate_user
    header = request.headers["Authorization"]
    token = header.split(" ").last if header

    begin
      decoded = JWT.decode(token, Rails.application.secret_key_base, true, { algorithm: "HS256" })[0]
      @current_user = User.find(decoded["user_id"])

      if @current_user.token_jti != decoded["jti"]
        render json: { error: "Token has been revoked", status: HttpStatus::UNAUTHORIZED }, status: :unauthorized
      end
    rescue JWT::ExpiredSignature
      render json: { error: "Token expired. Please login again.", status: HttpStatus::UNAUTHORIZED }, status: :unauthorized
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      render json: { error: "Unauthorized user", status: HttpStatus::UNAUTHORIZED }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end
end
