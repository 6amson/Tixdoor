class ComplaintDigestService
  def self.send_daily_pending_summary
    pending_complaints = Complaint.includes(:user).where(status: "pending").order(created_at: :desc)
    return if pending_complaints.empty?

    admins = User.where(user_type: "admin")
    return if admins.empty?

    admins.each do |admin|
      send_mailgun_email(
        to: admin.email,
        subject: "Daily Pending Complaints Digest (#{pending_complaints.count})",
        text: build_plain_text(pending_complaints),
        html: build_html(pending_complaints)
      )
    end
  rescue => e
    Rails.logger.error("Digest Error: #{e.message}")
  end

  def self.send_mailgun_email(to:, subject:, text:, html:)
    unless MailgunClient.send_message(MAILGUN_DOMAIN, {
      from: MAILGUN_FROM,
      to: to,
      subject: subject,
      text: text,
      html: html
    })
      raise HttpError.new("Failed to send digest email", status: HttpStatus::BAD_REQUEST)
    end
  end

  def self.build_plain_text(complaints)
    lines = complaints.map do |c|
      <<~TEXT
      Complaint by: #{c.user.email}
      Type: #{c.complaint_type}
      Created At: #{c.created_at.strftime('%Y-%m-%d %H:%M')}
      -----
      TEXT
    end
    "Daily Pending Complaints Summary\n\n" + lines.join("\n")
  end

  def self.build_html(complaints)
    rows = complaints.map do |c|
      <<~HTML
        <tr>
          <td style="padding: 8px; border: 1px solid #eee;">#{c.user.email}</td>
          <td style="padding: 8px; border: 1px solid #eee;">#{c.complaint_type}</td>
          <td style="padding: 8px; border: 1px solid #eee;">#{c.created_at.strftime('%Y-%m-%d %H:%M')}</td>
        </tr>
      HTML
    end

    <<~HTML
      <div style="font-family: Arial, sans-serif;">
        <h2 style="color: #333;">Daily Pending Complaints Digest</h2>
        <table style="width: 100%; border-collapse: collapse;">
          <thead>
            <tr>
              <th style="padding: 10px; border: 1px solid #eee;">Submitted By</th>
              <th style="padding: 10px; border: 1px solid #eee;">Type</th>
              <th style="padding: 10px; border: 1px solid #eee;">Created At</th>
            </tr>
          </thead>
          <tbody>
            #{rows.join}
          </tbody>
        </table>
        <p style="margin-top: 20px; font-size: 14px; color: #777;">
          Please review these complaints in the admin dashboard.
        </p>
      </div>
    HTML
  end
end
