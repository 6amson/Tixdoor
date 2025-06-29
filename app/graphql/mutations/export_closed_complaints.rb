module Mutations
  class ExportClosedComplaints < BaseMutation
    description "Export all complaints from last month as CSV"

    # Return type
    field :csv_data, String, null: false
    field :filename, String, null: false
    field :success, Boolean, null: false
    field :message, String, null: true

    def resolve
      begin
        csv_data = ComplaintExportService.closed_last_month_to_csv
        filename = "complaints_#{Date.current.strftime('%Y_%m_%d')}.csv"

        {
          csv_data: csv_data,
          filename: filename,
          success: true,
          message: "CSV export generated successfully"
        }
      rescue StandardError => e
        {
          csv_data: "",
          filename: "",
          success: false,
          message: "Export failed: #{e.message}"
        }
      end
    end
  end
end
