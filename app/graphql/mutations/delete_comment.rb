module Mutations
  class DeleteComment < Mutations::BaseMutation
    argument :comment_id, ID, required: true

    field :success, Boolean, null: false
    field :message, String, null: true

    def resolve(comment_id:)
      user = context[:current_user]
      result = ComplaintService.delete_comment(comment_id, user)
      {
        success: result[:success],
        message: result[:message]
      }
    rescue HttpError => e
      GraphQL::ExecutionError.new(e.message)
    end
  end
end
