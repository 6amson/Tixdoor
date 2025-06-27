
class ApplicationController < ActionController::API
  rescue_from StandardError, with: :handle_internal_server_error
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActionController::RoutingError, with: :handle_not_found
  rescue_from HttpError, with: :handle_http_error
rescue_from ArgumentError, with: :handle_internal_server_error

  def route_not_found
    raise ActionController::RoutingError.new("No route matches #{request.method} #{request.path}")
  end

  private

  def handle_http_error(error)
    render json: {
      status: error.status,
      error: error.message
    }, status: error.status
  end

  def handle_not_found(error)
    render json: {
      status: 404,
      error: error.message
      # message: error.message
    }, status: :not_found
  end

  def handle_internal_server_error(error)
    Rails.logger.error(error.full_message)
    render json: {
      status: 500,
      error: error.message
      # message: error.message
    }, status: :internal_server_error
  end

  rescue_from HttpError do |e|
    render json: {
        error: e.message,
        status: e.status
    }, status: e.status
  end
end
