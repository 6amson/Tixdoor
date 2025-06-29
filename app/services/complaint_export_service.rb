require "csv"

class ComplaintExportService
  def self.closed_last_month_to_csv
    complaints = Complaint.where("updated_at >= ?", 1.month.ago)

    CSV.generate(headers: true) do |csv|
      csv << [ "ID", "Type", "Complaint", "Status", "Submitted By", "Attachment" ]

      complaints.each do |complaint|
        csv << [
          complaint.id,
          complaint.complaint_type,
          complaint.complain.truncate(100),
          complaint.status.capitalize,
          complaint.user&.email || "Unknown",
          complaint.attachment || "Nil"
        ]
      end
    end
  end
end
