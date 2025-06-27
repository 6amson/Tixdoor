module Mutations
  class DeleteComplaint < Mutations::BaseMutation
    argument :complaint_id, ID, required: true

    field :success, Boolean, null: false
    field :message, String, null: true

    def resolve(complaint_id:)
      user = context[:current_user]
      result = ComplaintService.delete_complaint(complaint_id, user)
      {
        success: result[:success],
        message: result[:message]
      }
    rescue HttpError => e
      GraphQL::ExecutionError.new(e.message)
    end
  end
end
