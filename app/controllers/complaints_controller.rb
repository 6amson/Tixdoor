class ComplaintsController < ApplicationController
  before_action :authenticate_user

  rescue_from HttpError do |e|
    render json: { error: { message: e.message, status: e.status } }, status: e.status
  end

  def create
    result = ComplaintService.create_complaint(complaint_params.merge(user_id: current_user.id))
    render json: result, status: :created
  end

  def show
    result = ComplaintService.get_complaint(params[:id])
    render json: result
  end

  def index
    filters = {
      user_id: params[:user_id],
      status: params[:status],
      complaint_type: params[:complaint_type]
    }.compact

    result = ComplaintService.get_all_complaints(filters)
    render json: result
  end

  def add_comment
    user_type = current_user.admin? ? "admin" : "user"
    result = ComplaintService.add_comment(params[:id], user_type, params[:comment])
    render json: result, status: :created
  end

  def update_status
    result = ComplaintService.update_status(params[:id], params[:status])
    render json: result
  end

  private

  def complaint_params
    params.permit(:complaint_type, :complain, :attachment)
  end
end
