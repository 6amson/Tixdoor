class ComplaintService
  include ComplaintConstants

  def self.create_complaint(params)
    attachment_url = nil

    if params[:attachment].present?
      attachment_url = CloudinaryService.upload_image(params[:attachment])
      unless attachment_url
        raise HttpError.new(
          "Failed to upload attachment.",
          status: HttpStatus::BAD_REQUEST
        )
      end
    end

    complaint = Complaint.new(
      complaint_type: params[:complaint_type],
      user_id: params[:user_id],
      complain: params[:complain],
      attachment: attachment_url,
      status: COMPLAINT_STATUSES[:pending]
    )

    if complaint.save
      { success: true, complaint: complaint }
    else
      CloudinaryService.delete_image(attachment_url) if attachment_url
      raise HttpError.new(
        "Failed to create complaint.",
        status: HttpStatus::BAD_REQUEST
      )
    end
  end

  def self.get_complaint(id)
    complaint = Complaint.includes(:complaint_comments).find_by(id: id)

    unless complaint
      raise HttpError.new(
        "This complaint does not exist.",
        status: HttpStatus::NOT_FOUND
      )
    end

    { success: true, complaint: complaint }
  end

  def self.get_all_complaints(filters = {})
    complaints = Complaint.includes(:complaint_comments)

    complaints = complaints.where(user_id: filters[:user_id]) if filters[:user_id]
    complaints = complaints.where(status: filters[:status]) if filters[:status]
    complaints = complaints.where(complaint_type: filters[:complaint_type]) if filters[:complaint_type]

    complaints = complaints.order(created_at: :desc)

    { success: true, complaints: complaints }
  end

  def self.add_comment(complaint_id, user_type, comment_text)
    complaint = Complaint.find_by(id: complaint_id)
    unless complaint
      raise HttpError.new(
        "Complaint not found.",
        status: HttpStatus::NOT_FOUND
      )
    end

    comment = complaint.complaint_comments.build(
      user_type: user_type,
      comment: comment_text
    )

    if comment.save
      { success: true, comment: comment }
    else
      raise HttpError.new(
        "Failed to save comment.",
        status: HttpStatus::UNPROCESSABLE_ENTITY
      )
    end
  end

  def self.update_status(complaint_id, new_status)
    complaint = Complaint.find_by(id: complaint_id)
    unless complaint
      raise HttpError.new(
        "Complaint not found.",
        status: HttpStatus::NOT_FOUND
      )
    end

    if complaint.update(status: new_status)
      { success: true, complaint: complaint }
    else
      raise HttpError.new(
        "Failed to update complaint status.",
        status: HttpStatus::UNPROCESSABLE_ENTITY
      )
    end
  end
end