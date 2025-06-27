# app/services/complaint_notification_service.rb
class ComplaintNotificationService
  def self.notify_admins_of(complaint)
    admins = User.where(user_type: "admin")
    return if admins.empty?
    # Rails.logger.info "Notifying admins of new complaint: #{complaint.id} Complaint: #{complaint}"
    admins.each do |admin|
      send_mailgun_email(
        to: admin.email,
        subject: "New Complaint Submitted",
        text: build_plain_text(complaint),
        html: build_html(complaint),
      )
    end
rescue => e
    Rails.logger.error("Message for this error is this: #{e.message}")
  end

  def self.send_mailgun_email(to:, subject:, text:, html:)
    if MailgunClient.send_message(MAILGUN_DOMAIN, {
      from: MAILGUN_FROM,
      to: to,
      subject: subject,
      text: text,
      html: html
    })
    else
      raise HttpError.new(
        "Failed to send email.",
        status: HttpStatus::BAD_REQUEST,
      )
    end
  end

  def self.build_plain_text(complaint)
    <<~TEXT
      A new complaint was submitted by #{complaint.user.email}.
      Title: #{complaint.complaint_type}
      Status: #{complaint.status}
    TEXT
  end

  def self.build_html(complaint)
    <<~HTML
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; border: 1px solid #eee; padding: 20px; border-radius: 6px; background-color: #fafafa;">
        <h2 style="color: #333;">New Complaint Submitted</h2>
      #{"  "}
        <p style="font-size: 16px; color: #555;">
          A new complaint was submitted by#{" "}
          <strong style="color: #222;">#{complaint.user.email}</strong>.
        </p>

        <table style="width: 100%; border-collapse: collapse; margin-top: 15px;">
          <tr>
            <td style="padding: 8px; font-weight: bold; color: #444;">Title:</td>
            <td style="padding: 8px; color: #222;">#{complaint.complaint_type}</td>
          </tr>
          <tr>
            <td style="padding: 8px; font-weight: bold; color: #444;">Status:</td>
            <td style="padding: 8px; color: #222;">#{complaint.status.capitalize}</td>
          </tr>
          <tr>
            <td style="padding: 8px; font-weight: bold; color: #444;">Created At:</td>
            <td style="padding: 8px; color: #222;">#{complaint.created_at.strftime("%b %d, %Y %H:%M")}</td>
          </tr>
        </table>

        <p style="margin-top: 20px; font-size: 14px; color: #777;">
          You can log in to your admin dashboard to review the complaint.
        </p>

        <p style="margin-top: 30px; font-size: 12px; color: #aaa; text-align: center;">
          &copy; #{Time.now.year} Tixdoor Admin Notification
        </p>
      </div>
    HTML
  end
end
