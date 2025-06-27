class ComplaintsController < ApplicationController
  include UserAuthentication

  before_action :authenticate_user

  def create
    result = ComplaintService.create_complaint(complaint_params.merge(user_id: current_user.id))
    render json: result, status: :created
    rescue HttpError => e
    render_error(e)
  end

  def show
    result = ComplaintService.get_complaint(params[:id])
    render json: result
    rescue HttpError => e
    render_error(e)
  end

  def destroy
    result = ComplaintService.delete_complaint(params[:id], current_user)
    render json: result
    rescue HttpError => e
    render_error(e)
  end

  def delete_comment
  result = ComplaintService.delete_comment(params[:id], current_user)
  render json: result, status: :ok
rescue HttpError => e
  render_error(e)
end


  def index
    filters = {
      # user_id: params[:user_id],
      status: params[:status],
      complaint_type: params[:complaint_type]
    }.compact
    result = ComplaintService.get_all_complaints(
  filters,
  user: current_user,
  page: params[:page] || 1,
  per_page: params[:per_page] || 30
)
    render json: result
    rescue HttpError => e
    render_error(e)
  end

  def add_comment
    result = ComplaintService.add_comment(params[:id], current_user, params[:comment])
    render json: result, status: :created
  rescue HttpError => e
    render_error(e)
  end

  def update_status
    result = ComplaintService.update_status(params[:id], params[:status], current_user,)
    render json: result, status: :updated
  rescue HttpError => e
    render_error(e)
  end

  private

  def complaint_params
    params.permit(:complaint_type, :complain, :attachment)
  end

   def render_error(error)
    render json: {
        error: error.message,
        status: error.status
    }, status: error.status
  end
end
