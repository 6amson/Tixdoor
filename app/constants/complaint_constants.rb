module ComplaintConstants
  COMPLAINT_TYPES = {
    service_issue: "service_issue",
    payment_issue: "payment_issue", 
    technical_issue: "technical_issue",
    content_issue: "content_issue",
    other: "other"
  }.freeze

  COMPLAINT_STATUSES = {
    pending: "pending",
    in_progress: "in progress",
    resolved: "resolved",
    rejected: "rejected"
  }.freeze

  USER_TYPES = {
    regular: "regular",
    admin: "admin"
  }.freeze
end