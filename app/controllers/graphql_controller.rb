class GraphqlController < ApplicationController
  # Disable CSRF for GraphQL API
  # skip_before_action :verify_authenticity_token

  def execute
    variables = ensure_hash(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    context = {
      current_user: current_user,
      request: request,
    }

    # Rails.logger.debug("SHUTT: #{context}")
    # raise GraphQL::ExecutionError.new("Unauthorized ooo", extensions: { status: 401 }) unless context[:current_user]
    result = AppSchema.execute(query, variables: variables, context: context, operation_name: operation_name)
    render json: result
  rescue => e
    raise e unless Rails.env.development?
    handle_error_in_development e
  end

  private

  # def current_user
  #   auth_header = request.headers["Authorization"]
  #   return nil unless auth_header.present?

  #   token = auth_header.split(" ").last

  #   begin
  #     payload = JWT.decode(token, Rails.application.secret_key_base, true, { algorithm: "HS256" }).first
  #     user = User.find_by(id: payload["user_id"])
  #     user if user&.token_jti == payload["jti"]
  #   rescue JWT::DecodeError, JWT::ExpiredSignature
  #     nil
  #   end
  # end

  # Add this to your GraphQL controller temporarily to debug
  def current_user
    Rails.logger.info "=== Secret Key Base Debug ==="
    Rails.logger.info "ENV SECRET_KEY_BASE present: #{ENV["SECRET_KEY_BASE"].present?}"
    Rails.logger.info "ENV SECRET_KEY_BASE length: #{ENV["SECRET_KEY_BASE"]&.length}"
    Rails.logger.info "Rails.application.secret_key_base present: #{Rails.application.secret_key_base.present?}"
    Rails.logger.info "Rails.application.secret_key_base length: #{Rails.application.secret_key_base&.length}"
    Rails.logger.info "Rails.application.credentials.secret_key_base present: #{Rails.application.credentials.secret_key_base.present?}"

    # Check if they're the same
    env_secret = ENV["SECRET_KEY_BASE"]
    rails_secret = Rails.application.secret_key_base
    Rails.logger.info "Secrets match: #{env_secret} : #{rails_secret}, #{env_secret == rails_secret}"

    # Continue with your existing logic...
    auth_header = request.headers["Authorization"]
    return nil unless auth_header.present?

    token = auth_header.split(" ").last

    begin
      # Try with ENV secret first
      if env_secret.present?
        Rails.logger.info "Trying to decode with ENV SECRET_KEY_BASE"
        payload = JWT.decode(token, env_secret, true, { algorithm: "HS256" }).first
        Rails.logger.info "Successfully decoded with ENV secret"
      else
        Rails.logger.info "Trying to decode with Rails.application.secret_key_base"
        payload = JWT.decode(token, rails_secret, true, { algorithm: "HS256" }).first
        Rails.logger.info "Successfully decoded with Rails secret"
      end

      user = User.find_by(id: payload["user_id"])
      user if user&.token_jti == payload["jti"]
    rescue JWT::DecodeError => e
      Rails.logger.error "JWT Decode Error: #{e.message}"

      # Try with the other secret if available
      begin
        if env_secret.present? && env_secret != rails_secret
          Rails.logger.info "Retrying with different secret"
          payload = JWT.decode(token, env_secret, true, { algorithm: "HS256" }).first
          user = User.find_by(id: payload["user_id"])

          #     begin
          # decoded = JWT.decode(token, Rails.application.secret_key_base, true, { algorithm: "HS256" })[0]
          # @current_user = User.find(decoded["user_id"])

          # if @current_user.token_jti != decoded["jti"]
          #   render json: { error: "Token has been revoked", status: HttpStatus::UNAUTHORIZED }, status: :unauthorized
          # end
          return user if user&.token_jti == payload["jti"]
        end
      rescue => retry_error
        Rails.logger.error "Retry also failed: #{retry_error.message}"
      end

      nil
    rescue JWT::ExpiredSignature => e
      Rails.logger.error "JWT Expired: #{e.message}"
      nil
    end
  end

  def ensure_hash(ambiguous_param)
    case ambiguous_param
    when String
      if ambiguous_param.present?
        ensure_hash(JSON.parse(ambiguous_param))
      else
        {}
      end
    when Hash, ActionController::Parameters
      ambiguous_param
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{ambiguous_param}"
    end
  end

  def handle_error_in_development(e)
    logger.error e.message
    logger.error e.backtrace.join("\n")

    render json: { errors: [{ message: e.message, backtrace: e.backtrace }], data: {} }, status: 500
  end
end
