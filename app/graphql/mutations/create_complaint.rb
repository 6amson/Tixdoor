module Mutations
  class CreateComplaint < Mutations::BaseMutation
    argument :complaint_type, String, required: true
    argument :complain, String, required: true
    argument :attachment, ApolloUploadServer::Upload, required: false

    field :success, Boolean, null: false
    field :complaint, Types::ComplaintType, null: true

    def resolve(complaint_type:, complain:, attachment: nil)
      user = context[:current_user]
      raise GraphQL::ExecutionError, "Authentication required" if user.nil?
      Rails.logger.info("EXCESSESS USER: #{user}")
      params = {
        complaint_type: complaint_type,
        user_id: user.id,
        complain: complain,
        attachment: attachment,
      }

      result = ComplaintService.create_complaint(params)
      {
        success: result[:success],
        complaint: result[:complaint],
      }
    rescue HttpError => e
      GraphQL::ExecutionError.new(e.message)
    end
  end
end
