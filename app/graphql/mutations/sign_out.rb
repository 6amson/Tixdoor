module Mutations
  class SignOut < Mutations::BaseMutation
    argument :client_mutation_id, String, required: false
    
    field :success, Boolean, null: false
    field :message, String, null: true

    def resolve
      user = context[:current_user]
      result = UserService.signout(user)
      {
        success: result[:success],
        message: result[:message]
      }
    rescue HttpError => e
      GraphQL::ExecutionError.new(e.message)
    end
  end
end


