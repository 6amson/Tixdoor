
class ApplicationController < ActionController::API
  # skip_before_action :verify_authenticity_token
  # protect_from_forgery with: :null_session

  rescue_from ActiveRecord::ConnectionNotEstablished do |e|
  render json: {
    error: {
      message: "Database connection error. Please try again later.",
      details: e.message
    }
  }, status: :service_unavailable
end

  rescue_from HttpError do |e|
    render json: {
      error: {
        message: e.message,
        status: e.status
      }
    }, status: e.status
  end
end
