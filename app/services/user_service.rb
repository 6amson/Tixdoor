class UserService
  include ComplaintConstants

  def self.signin(email, password)
    user = User.find_by(email: email)

    unless user&.authenticate(password)
      raise HttpError.new(
        "Invalid email or password.",
        status: HttpStatus::UNAUTHORIZED,
      )
    end

    token = generate_token(user)
    { success: true, user: user, token: token }
  end

  def self.signup(params)
    # Validate user type
    unless params[:user_type].in?([USER_TYPES[:regular], USER_TYPES[:admin]])
      raise HttpError.new(
        "Invalid user type. Must be 'regular' or 'admin'.",
        status: HttpStatus::BAD_REQUEST,
      )
    end

    # Check if user already exists
    existing_user = User.find_by(email: params[:email])
    if existing_user
      raise HttpError.new(
        "User with this email already exists.",
        status: HttpStatus::BAD_REQUEST,
      )
    end

    # Create new user
    user = User.new(
      email: params[:email].downcase.strip,
      password: params[:password],
      user_type: params[:user_type] || ComplaintConstants::USER_TYPES[:regular],
    )
    user.token_jti = SecureRandom.uuid

    if params[:admin_code] && params[:admin_code] != ""
      unless params[:admin_code] == ENV["ADMIN_CODE"]
        Rails.logger.info("Comparison failed - codes don't match")
        raise HttpError.new(
          "Invalid admin code.",
          status: HttpStatus::FORBIDDEN,
        )
      end
      user.user_type = ComplaintConstants::USER_TYPES[:admin]
    end

    if user.save
      token = generate_token(user)
      { success: true, user: user, token: token }
    else
      raise HttpError.new(
        "Failed to create user: #{user.errors.full_messages.join(", ")}",
        status: HttpStatus::UNPROCESSABLE_ENTITY,
      )
    end
  end

  def self.signout(user)
    unless user
      raise HttpError.new(
        "You are not signed in.",
        status: HttpStatus::UNAUTHORIZED,
      )
    end

    user.update(token_jti: SecureRandom.uuid)
    { success: true, message: "Successfully signed out." }
  end

  def self.profile(user:, page:, per_page:)
    # raise HttpError.new("Unauthorized", status: HttpStatus::FORBIDDEN) unless user
    Rails.logger.info("Fetching profile for user: #{user}, page: #{page}, per_page: #{per_page}")
    raise HttpError.new("User does not exist: #{user.errors.full_messages.join(", ")}", status: HttpStatus::NOT_FOUND) unless user
    complaints = Complaint.includes(:complaint_comments, :user)

    if user.user_type == ComplaintConstants::USER_TYPES[:regular]
      complaints = complaints.where(user_id: user.id)
    end

    complaints = complaints.order(created_at: :desc)
    paginated = complaints.page(page).per(per_page)

    {
      success: true,
      user: user,
      complaints: paginated.as_json(include: {
                                      user: { only: [:email] },
                                      complaint_comments: { only: [:id, :comment, :user_type, :created_at] },
                                    }),
      pagination: {
        current_page: paginated.current_page,
        total_pages: paginated.total_pages,
        total_count: paginated.total_count,
      },
    }
  end

  def self.get_all_enums
    {
      complaint_types: COMPLAINT_TYPES.values.map(&:to_s),
      complaint_statuses: COMPLAINT_STATUSES.values.map(&:to_s),
      user_types: USER_TYPES.values.map(&:to_s),
    }
  end

  private

  def self.generate_token(user)
    payload = {
      user_id: user.id,
      jti: user.token_jti,
      exp: 24.hours.from_now.to_i,
    }
    JWT.encode(payload, Rails.application.secret_key_base, "HS256")
  end
end
