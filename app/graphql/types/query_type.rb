# app/graphql/types/query_type.rb
module Types
  class QueryType < Types::BaseObject
   def authenticate_user!
      context[:current_user] || raise(GraphQL::ExecutionError, "Unauthorized access, log in.")
    end

    def current_user
      context[:current_user]
    end
    field :complaint, Types::ComplaintType, null: true do
      argument :id, ID, required: true
    end

    field :complaints, Types::ComplaintsPayloadType, null: false do
      argument :page, Integer, required: false, default_value: 1
      argument :per_page, Integer, required: false, default_value: 10
      argument :status, String, required: false
      argument :complaint_type, String, required: false
    end

    field :profile, Types::ProfilePayloadType, null: false do
      argument :page, Integer, required: false, default_value: 1
      argument :per_page, Integer, required: false, default_value: 10
    end

    field :enums, Types::EnumsPayloadType, null: false

    def complaint(id:)
      user = authenticate_user!
      result = ComplaintService.get_complaint(id)
      result[:complaint]
    rescue HttpError => e
      GraphQL::ExecutionError.new(e.message)
    end

    def complaints(page:, per_page:, status: nil, complaint_type: nil)
      user = authenticate_user!
      filters = {
        status: status,
        complaint_type: complaint_type
      }.compact
      result = ComplaintService.get_all_complaints(filters, user: user, page: page, per_page: per_page)
      {
        success: result[:success],
        complaints: result[:complaints],
        pagination: result[:pagination]
      }
    rescue HttpError => e
      GraphQL::ExecutionError.new(e.message)
    end

    def profile(page:, per_page:)
      user = authenticate_user!
      result = UserService.profile(user: user, page: page, per_page: per_page)
      {
        success: result[:success],
        user: result[:user],
        complaints: result[:complaints],
        pagination: result[:pagination]
      }
    rescue HttpError => e
      GraphQL::ExecutionError.new(e.message)
    end

    def enums
      UserService.get_all_enums
    end
  end
end
