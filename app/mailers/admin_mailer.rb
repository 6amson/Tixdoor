class AdminMailer < ApplicationMailer
  default from: "contact.cospace.live" # Or your Mailgun sender

  def new_complaint_notification(admin, complaint)
    @admin = admin
    @complaint = complaint
    mail(to: admin.email, subject: "New Complaint Submitted")
  end
end
