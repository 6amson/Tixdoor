module Mutations
  class AddComment < Mutations::BaseMutation
    argument :complaint_id, ID, required: true
    argument :comment, String, required: true

    field :success, Boolean, null: false
    field :comment, Types::ComplaintCommentType, null: true

    def resolve(complaint_id:, comment:)
      user = context[:current_user]
      result = ComplaintService.add_comment(complaint_id, user, comment)
      {
        success: result[:success],
        comment: result[:comment]
      }
    rescue HttpError => e
      GraphQL::ExecutionError.new(e.message)
    end
  end
end
