module CommentRules
  extend ActiveSupport::Concern
  include ComplaintConstants

  enum userTypes: USER_TYPES

  included do
    validate :admin_comment_must_exist_before_user_comment, if: :requires_admin_comment?
  end

  private

  def requires_admin_comment?
    respond_to?(:user_type) && user_type != USER_TYPES[:admin]
  end

  def admin_comment_must_exist_before_user_comment
    return if complaint.complaint_comments.where(user_type:  USER_TYPES[:admin]).exists?
    errors.add(:base, "Admin comment is required before proceeding.")
  end
end
