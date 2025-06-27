class ComplaintService
  include ComplaintConstants

  def self.create_complaint(params)
    attachment_url = nil

    if params[:attachment].present?
      attachment_url = CloudinaryService.upload_image(params[:attachment])
      unless attachment_url
        raise HttpError.new(
          "Failed to upload attachment.",
          status: HttpStatus::BAD_REQUEST,
        )
      end
    end

    user = User.find_by(id: params[:user_id])

    unless user
      raise HttpError.new(
        "User not found.",
        status: HttpStatus::NOT_FOUND,
      )
    end

    unless user.user_type == USER_TYPES[:regular]
      raise HttpError.new(
        "Admins can not complain, be fr.",
        status: HttpStatus::FORBIDDEN,
      )
    end

    complaint = Complaint.new(
      complaint_type: params[:complaint_type],
      user_id: params[:user_id],
      complain: params[:complain],
      attachment: attachment_url,
      status: COMPLAINT_STATUSES[:pending],
    )

    if complaint.save
      begin
        ComplaintNotificationService.notify_admins_of(complaint)
        { success: true, complaint: complaint }
      end
    else
      CloudinaryService.delete_image(attachment_url) if attachment_url
      raise HttpError.new(
        "Failed to create complaint.",
        status: HttpStatus::BAD_REQUEST,
      )
    end
  end

  def self.get_complaint(id)
    complaint = Complaint.includes(:complaint_comments).find_by(id: id)

    unless complaint
      raise HttpError.new(
        "This complaint does not exist.",
        status: HttpStatus::NOT_FOUND,
      )
    end

    { success: true, complaint: complaint.as_json(
      include: {
        complaint_comments: {
          only: [ :id, :comment, :user_type, :created_at ]
        }
      },
    ) }
  end

  def self.get_all_complaints(filters = {}, user:, page:, per_page:)
    unless user
      raise HttpError.new(
        "Unauthorized access.",
        status: HttpStatus::FORBIDDEN,
      )
    end
    filters = filters.compact_blank

    complaints = Complaint.includes(:complaint_comments)
    complaints = complaints.where(user_id: user.id) if user.user_type === USER_TYPES[:regular]
    complaints = complaints.where(status: filters[:status]) if filters[:status]
    complaints = complaints.where(complaint_type: filters[:complaint_type]) if filters[:complaint_type]
    complaints = complaints.order(created_at: :desc)
    complaints = complaints.includes(:complaint_comments)
    paginated = complaints.page(page).per(per_page)

    {
      success: true,
      complaints: paginated.as_json(
        include: {
          complaint_comments: {
            only: [ :id, :comment, :user_type, :created_at ]
          }
        },
      ),
      pagination: {
        current_page: paginated.current_page,
        total_pages: paginated.total_pages,
        total_count: paginated.total_count
      }
    }
  end

  def self.add_comment(complaint_id, user, comment_text)
    complaint = Complaint.find_by(id: complaint_id)
    is_there_admin_comment = nil

    unless complaint
      raise HttpError.new(
        "Complaint not found.",
        status: HttpStatus::NOT_FOUND,
      )
    end

    is_there_admin_comment = complaint.complaint_comments.where(user_type: USER_TYPES[:admin]).empty?
    comment = complaint.complaint_comments.build(
      user_type: user.user_type,
      comment: comment_text,
      user_email: user.email,
    )

    if comment.save
      if user.user_type == USER_TYPES[:admin] && is_there_admin_comment
        complaint.update(status: COMPLAINT_STATUSES[:in_progress])
      end
      { success: true, comment: comment }
    else
      Rails.logger.error("Failed to save comment: #{comment.errors.full_messages.join(", ")}")
      raise HttpError.new(
        "Failed to save comment: #{comment.errors.full_messages.join(", ")}",
        status: HttpStatus::UNPROCESSABLE_ENTITY,
      )
    end
  end

  def self.update_status(complaint_id, new_status, user)
    unless new_status.present? && COMPLAINT_STATUSES.key?(new_status.to_sym)
      raise HttpError.new(
        "Invalid or missing status. Valid statuses are: #{COMPLAINT_STATUSES.keys.join(", ")}",
        status: HttpStatus::BAD_REQUEST,
      )
    end
    Rails.logger.info("Updating complaint status: #{complaint_id} to #{new_status} by user: #{user}")
    unless user && user.user_type == USER_TYPES[:admin]
      raise HttpError.new(
        "Only admins can update complaint status.",
        status: HttpStatus::FORBIDDEN,
      )
    end
    unless complaint_id
      raise HttpError.new(
        "Complaint Id is required.",
        status: HttpStatus::NOT_FOUND,
      )
    end
    complaint = Complaint.find_by(id: complaint_id)
    unless complaint
      raise HttpError.new(
        "Complaint not found.",
        status: HttpStatus::NOT_FOUND,
      )
    end

    if complaint.update(status: new_status)
      { success: true, complaint: complaint }
    else
      raise HttpError.new(
        "Failed to update complaint status.",
        status: HttpStatus::UNPROCESSABLE_ENTITY,
      )
    end
  end

  def self.delete_complaint(complaint_id, current_user)
    complaint = Complaint.find_by(id: complaint_id)

    raise HttpError.new("Complaint not found", status: HttpStatus::NOT_FOUND) unless complaint
    Rails.logger.info("Deleting complaint with user Id: #{complaint.user_id} by user: #{current_user.id}")

    unless complaint.user_id.to_i == current_user.id.to_i || current_user.user_type == USER_TYPES[:admin]
      raise HttpError.new(
        "You are not authorized to delete this complaint.",
        status: HttpStatus::FORBIDDEN,
      )
    end

    attachment_url = complaint.attachment
    if attachment_url.present?
      unless CloudinaryService.delete_image(attachment_url)
        raise HttpError.new(
          "Failed to delete attachment on this complaint.",
          status: HttpStatus::BAD_REQUEST,
        )
      end
    end

    if complaint.complaint_comments.destroy_all
      if complaint.destroy
        { success: true, message: "Complaint deleted successfully" }
      else
        raise HttpError.new("Failed to delete complaint", status: HttpStatus::INTERNAL_SERVER_ERROR)
      end
    else
      raise HttpError.new("Failed to delete comments", status: HttpStatus::INTERNAL_SERVER_ERROR)
    end
  end

  def self.delete_comment(comment_id, user)
    comment = ComplaintComment.find_by(id: comment_id)
    raise HttpError.new("Comment not found", status: HttpStatus::NOT_FOUND) unless comment

    unless comment.complaint.user_id.to_i == user.id.to_i || user.user_type == USER_TYPES[:admin]
      raise HttpError.new("You are not authorized to delete this comment", status: HttpStatus::FORBIDDEN)
    end

    comment.destroy!

    {
      success: true,
      message: "Comment deleted successfully"
    }
  end
end
