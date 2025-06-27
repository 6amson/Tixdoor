module Mutations
  class UpdateComplaintStatus < Mutations::BaseMutation
    argument :complaint_id, ID, required: true
    argument :status, String, required: true

    field :success, Boolean, null: false
    field :complaint, Types::ComplaintType, null: true

    def resolve(complaint_id:, status:)
      user = context[:current_user]
      result = ComplaintService.update_status(complaint_id, status, user)
      {
        success: result[:success],
        complaint: result[:complaint]
      }
    rescue HttpError => e
      GraphQL::ExecutionError.new(e.message)
    end
  end
end
