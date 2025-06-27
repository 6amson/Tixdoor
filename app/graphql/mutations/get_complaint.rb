module Queries
  class GetComplaint < Queries::BaseQuery
    type Types::ComplaintType, null: true
    argument :id, ID, required: true

    def resolve(id:)
      result = ComplaintService.get_complaint(id)
      result[:complaint]
    rescue HttpError => e
      raise GraphQL::ExecutionError, e.message
    end
  end
end
