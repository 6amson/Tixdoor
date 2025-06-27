module ComplaintConstants
  COMPLAINT_TYPES = {
    service_issue: "service issue",
    payment_issue: "payment issue",
    technical_issue: "technical issue",
    content_issue: "content issue",
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
