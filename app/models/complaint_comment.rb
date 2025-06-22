class ComplaintComment < ApplicationRecord
  include ComplaintConstants
  include CommentRules

  belongs_to :complaint
  belongs_to :user

  enum user_type: USER_TYPES

  validates :user_type, presence: true, inclusion: { in: USER_TYPES.keys.map(&:to_s) }
  validates :comment, presence: true
end
