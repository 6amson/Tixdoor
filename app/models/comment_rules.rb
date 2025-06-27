module CommentRules
  extend ActiveSupport::Concern
  include ComplaintConstants

  included do
    validate :admin_comment_must_exist_before_user_comment, if: :requires_admin_comment?
    validate :cannot_complain_after_resolve, if: :requires_admin_comment?
  end

  private

  def requires_admin_comment?
    respond_to?(:user_type) && user_type != USER_TYPES[:admin]
  end

  def admin_comment_must_exist_before_user_comment
    return if complaint.complaint_comments.where(user_type:  USER_TYPES[:admin]).exists?
    raise HttpError.new(
      "Admin comment is required before proceeding.",
      status: HttpStatus::UNPROCESSABLE_ENTITY
    )
  end

  def cannot_complain_after_resolve
    return unless complaint.status == COMPLAINT_STATUSES[:resolved]

    raise HttpError.new(
      "You cannot add comments after the complaint has been resolved.",
      status: HttpStatus::UNPROCESSABLE_ENTITY
    )
  end
end
