class AdminMailer < ApplicationMailer
  default from: "contact.cospace.live" # Or your Mailgun sender

  def new_complaint_notification(admin, complaint)
    @admin = admin
    @complaint = complaint
    mail(to: admin.email, subject: "New Complaint Submitted")
  end

  def daily_pending_digest(admin, complaints)
    @admin = admin
    @complaints = complaints

    mail(
      to: @admin.email,
      subject: "Daily Pending Complaints Digest (#{@complaints.count} pending)",
    )
  end
end
