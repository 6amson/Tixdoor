class UserService


  def self.signin(email, password)
    user = User.find_by(email: email)

    unless user&.authenticate(password)
      raise HttpError.new(
        "Invalid email or password.",
        status: HttpStatus::UNAUTHORIZED
      )
    end

    token = generate_token(user)
    { success: true, user: user, token: token }
  end

  def self.signup(params)
    user = User.new(params)
    user.token_jti = SecureRandom.uuid

    if user.save
      token = generate_token(user)
      { success: true, user: user, token: token }
    else
      raise HttpError.new(
        "Failed to create user: #{user.errors.full_messages.join(', ')}",
        status: HttpStatus::UNPROCESSABLE_ENTITY
      )
    end
  end

  def self.signout(user)
    unless user
      raise HttpError.new(
        "You are not signed in.",
        status: HttpStatus::UNAUTHORIZED
    )
    end

    user.update(token_jti: SecureRandom.uuid)
    { success: true, message: "Successfully signed out." }
  end

  private

  def self.generate_token(user)
    payload = {
      user_id: user.id,
      jti: user.token_jti,
      exp: 24.hours.from_now.to_i
    }
    JWT.encode(payload, Rails.application.secret_key_base, 'HS256')
  end
end
