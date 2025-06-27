require 'csv'

class ComplaintExportService
  def self.closed_last_month_to_csv
    complaints = Complaint.where(status: 'closed')
                          .where('updated_at >= ?', 1.month.ago)

    CSV.generate(headers: true) do |csv|
      csv << ['ID', 'Type', 'Description', 'Status', 'Submitted By', 'Updated At']

      complaints.each do |complaint|
        csv << [
          complaint.id,
          complaint.complaint_type,
          complaint.description.truncate(100),
          complaint.status.capitalize,
          complaint.user&.email || 'Unknown',
          complaint.updated_at.strftime('%Y-%m-%d %H:%M')
        ]
      end
    end
  end
end
