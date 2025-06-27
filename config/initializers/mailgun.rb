MailgunClient = Mailgun::Client.new(ENV["MAILGUN_API_KEY"])
MAILGUN_DOMAIN = ENV["MAILGUN_DOMAIN"]
MAILGUN_FROM = ENV["MAILGUN_SENDER_EMAIL"] || "no-reply@yourdomain.com"
