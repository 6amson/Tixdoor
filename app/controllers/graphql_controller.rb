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
    auth_header = request.headers["Authorization"]
    return nil unless auth_header.present?

    token = auth_header.split(" ").last

    begin
      # Use ENV directly - don't trust Rails.application.secret_key_base
      secret = ENV["SECRET_KEY_BASE"]

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
