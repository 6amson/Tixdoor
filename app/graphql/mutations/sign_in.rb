module Mutations
  class SignIn < Mutations::BaseMutation
    # skip_authentication!

    argument :email, String, required: true
    argument :password, String, required: true

    field :success, Boolean, null: false
    field :user, Types::UserType, null: true
    field :token, String, null: true

    def resolve(email:, password:)
      result = UserService.signin(email, password)
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
