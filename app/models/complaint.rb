class Complaint < ApplicationRecord
 include ComplaintConstants
  has_many :complaint_comments, dependent: :destroy
  enum complaint_type: COMPLAINT_TYPES
  enum status: COMPLAINT_STATUSES

  validates :complaint_type, presence: true, inclusion: { in: COMPLAINT_TYPES.keys.map(&:to_s) }
  validates :user_id, presence: true
  validates :status, presence: true, inclusion: { in: COMPLAINT_STATUSES.keys.map(&:to_s) }
  validates :complain, presence: true

  belongs_to :user
end
