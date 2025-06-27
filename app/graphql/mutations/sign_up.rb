module Mutations
  class SignUp < Mutations::BaseMutation
    argument :email, String, required: true
    argument :password, String, required: true
    argument :user_type, String, required: false
    argument :admin_code, String, required: false

    field :success, Boolean, null: false
    field :user, Types::UserType, null: true
    field :token, String, null: true

    def resolve(email:, password:, user_type: "regular", admin_code:)
      params = {
        email: email,
        password: password,
        user_type: user_type,
        admin_code: admin_code
      }
      result = UserService.signup(params)
      {
        success: result[:success],
        user: result[:user],
        token: result[:token]
      }
    rescue HttpError => e
      GraphQL::ExecutionError.new(e.message)
    end
  end
end
