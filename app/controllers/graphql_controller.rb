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
    Rails.logger.info "=== COMPREHENSIVE SECRET DEBUG ==="

    # 1. Environment variables
    Rails.logger.info "ENV['SECRET_KEY_BASE']: #{ENV["SECRET_KEY_BASE"]}"
    Rails.logger.info "ENV['RAILS_MASTER_KEY']: #{ENV["RAILS_MASTER_KEY"]}"

    # 2. All possible Rails secret sources
    Rails.logger.info "Rails.application.credentials.secret_key_base: #{Rails.application.credentials.secret_key_base.inspect}"
    Rails.logger.info "Rails.application.secrets.secret_key_base: #{Rails.application.secrets.secret_key_base.inspect}"
    Rails.logger.info "Rails.application.secret_key_base: #{Rails.application.secret_key_base.inspect}"

    # 3. Configuration values
    Rails.logger.info "Rails.application.config.secret_key_base: #{Rails.application.config.secret_key_base.inspect}"

    # 4. Check if there are any initializers setting this
    Rails.logger.info "Rails.application.config.secret_token: #{Rails.application.config.secret_token.inspect}"

    # 5. Check credentials config
    Rails.logger.info "Rails.application.credentials.config.keys: #{Rails.application.credentials.config.keys}"

    # 6. Check secrets config (if it exists)
    begin
      Rails.logger.info "Rails.application.secrets.inspect: #{Rails.application.secrets.inspect}"
    rescue => e
      Rails.logger.info "Secrets error: #{e.message}"
    end

    # 7. Check if master key is working
    Rails.logger.info "Can decrypt credentials: #{Rails.application.credentials.config.present?}"

    # 8. Environment info
    Rails.logger.info "Rails.env: #{Rails.env}"
    Rails.logger.info "Rails.application.class: #{Rails.application.class}"

    # Continue with your existing auth logic...
    auth_header = request.headers["Authorization"]
    return nil unless auth_header.present?

    token = auth_header.split(" ").last

    begin
      # For now, force use of ENV variable
      secret = ENV["SECRET_KEY_BASE"]
      Rails.logger.info "FORCING ENV secret: #{secret}"

      payload = JWT.decode(token, secret, true, { algorithm: "HS256" }).first
      user = User.find_by(id: payload["user_id"])
      user if user&.token_jti == payload["jti"]
    rescue JWT::DecodeError, JWT::ExpiredSignature => e
      Rails.logger.error "JWT Error: #{e.message}"
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
