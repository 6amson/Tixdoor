module Mutations
  class ExportClosedComplaints < Mutations::BaseMutation
    field :csv_base64, String, null: false

    def resolve
      user = context[:current_user]
      unless user&.admin?
        raise GraphQL::ExecutionError.new("Unauthorized", extensions: { code: 401 })
      end

      csv_data = ComplaintExportService.closed_last_month_to_csv
      base64_encoded = Base64.strict_encode64(csv_data)

      { csv_base64: base64_encoded }
    end
  end
end
