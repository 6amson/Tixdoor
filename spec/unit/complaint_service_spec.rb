# spec/unit/services/complaint_service_spec.rb
require "rails_helper"

RSpec.describe ComplaintService, type: :service do
  let(:regular_user) { create(:user, user_type: "regular") }
  let(:admin_user) { create(:user, user_type: "admin") }
  let(:complaint) { create(:complaint, user: regular_user) }
  let(:complaint_params) do
    {
      complaint_type: "technical_issue",
      user_id: regular_user.id,
      complain: "Test complaint",
      attachment: nil
    }
  end

  describe ".create_complaint" do
    context "with valid parameters" do
      it "creates a complaint successfully" do
        allow(ComplaintNotificationService).to receive(:notify_admins_of)
        result = ComplaintService.create_complaint(complaint_params)

        expect(result[:success]).to be true
        expect(result[:complaint]).to be_a(Complaint)
        expect(result[:complaint].complaint_type).to eq("technical_issue")
        expect(result[:complaint].status).to eq("pending")
      end

      it "notifies admins after creation" do
        expect(ComplaintNotificationService).to receive(:notify_admins_of)

        ComplaintService.create_complaint(complaint_params)
      end
    end

    context "with attachment" do
      let(:attachment) { fixture_file_upload("test_image.png", "image/png") }
      let(:params_with_attachment) { complaint_params.merge(attachment: attachment) }

      it "uploads attachment and creates complaint" do
        allow(CloudinaryService).to receive(:upload_image).and_return("http://example.com/image.png")
        allow(ComplaintNotificationService).to receive(:notify_admins_of)

        result = ComplaintService.create_complaint(params_with_attachment)
        Rails.logger.info("RESULTS OUT: #{result}")

        expect(result[:success]).to be true
        expect(result[:complaint].attachment).to eq("http://example.com/image.png")
      end

      it "raises error when attachment upload fails" do
        allow(CloudinaryService).to receive(:upload_image).and_return(nil)

        expect {
          ComplaintService.create_complaint(params_with_attachment)
        }.to raise_error(HttpError) do |error|
          expect(error.message).to eq("Failed to upload attachment.")
          expect(error.status).to eq(HttpStatus::BAD_REQUEST)
        end
      end

      it "deletes uploaded attachment if complaint save fails" do
        allow(CloudinaryService).to receive(:upload_image).and_return("http://example.com/image.jpg")
        allow(CloudinaryService).to receive(:delete_image).and_return(true)
        allow_any_instance_of(Complaint).to receive(:save).and_return(false)

        expect(CloudinaryService).to receive(:delete_image).with("http://example.com/image.jpg")

        expect {
          ComplaintService.create_complaint(params_with_attachment)
        }.to raise_error(HttpError)
      end
    end

    context "with invalid user" do
      it "raises error when user not found" do
        invalid_params = complaint_params.merge(user_id: 999)

        expect {
          ComplaintService.create_complaint(invalid_params)
        }.to raise_error(HttpError) do |error|
          expect(error.message).to eq("User not found.")
          expect(error.status).to eq(HttpStatus::NOT_FOUND)
        end
      end

      it "raises error when user is admin" do
        admin_params = complaint_params.merge(user_id: admin_user.id)

        expect {
          ComplaintService.create_complaint(admin_params)
        }.to raise_error(HttpError) do |error|
          expect(error.message).to eq("Admins can not complain, be fr.")
          expect(error.status).to eq(HttpStatus::FORBIDDEN)
        end
      end
    end

    context "when complaint save fails" do
      it "raises error" do
        allow_any_instance_of(Complaint).to receive(:save).and_return(false)

        expect {
          ComplaintService.create_complaint(complaint_params)
        }.to raise_error(HttpError) do |error|
          expect(error.message).to eq("Failed to create complaint.")
          expect(error.status).to eq(HttpStatus::BAD_REQUEST)
        end
      end
    end
  end

  describe ".get_complaint" do
    it "returns complaint with comments" do
      comment = create(:complaint_comment, complaint: complaint)

      result = ComplaintService.get_complaint(complaint.id)

      expect(result[:success]).to be true
      expect(result[:complaint]["id"]).to eq(complaint.id)
      expect(result[:complaint]["complaint_comments"]).to be_present
    end

    it "returns complaint with empty comments if none exist" do
      result = ComplaintService.get_complaint(complaint.id)

      expect(result[:success]).to be true
      expect(result[:complaint]["id"]).to eq(complaint.id)
      expect(result[:complaint]["complaint_comments"]).to eq([])
    end

    it "raises error when complaint not found" do
      expect {
        ComplaintService.get_complaint(999)
      }.to raise_error(HttpError) do |error|
        expect(error.message).to eq("This complaint does not exist.")
        expect(error.status).to eq(HttpStatus::NOT_FOUND)
      end
    end
  end

  describe ".get_all_complaints" do
    let!(:complaint1) { create(:complaint, user: regular_user, status: "pending") }
    let!(:complaint2) { create(:complaint, user: regular_user, status: "in_progress") }
    let!(:admin_complaint) { create(:complaint, user: create(:user)) }

    context "for regular user" do
      it "returns only user complaints" do
        result = ComplaintService.get_all_complaints({}, user: regular_user, page: 1, per_page: 10)

        expect(result[:success]).to be true
        expect(result[:complaints].size).to eq(2)
        expect(result[:pagination][:total_count]).to eq(2)
      end

      it "filters by status" do
        result = ComplaintService.get_all_complaints(
          { status: "pending" },
          user: regular_user,
          page: 1,
          per_page: 10,
        )

        expect(result[:complaints].size).to eq(1)
        expect(result[:complaints].first["status"]).to eq("pending")
      end
    end

    context "for admin user" do
      it "returns all complaints" do
        result = ComplaintService.get_all_complaints({}, user: admin_user, page: 1, per_page: 10)

        expect(result[:success]).to be true
        expect(result[:complaints].size).to eq(3)
      end
    end

    context "without user" do
      it "raises unauthorized error" do
        expect {
          ComplaintService.get_all_complaints({}, user: nil, page: 1, per_page: 10)
        }.to raise_error(HttpError) do |error|
          expect(error.message).to eq("Unauthorized access.")
          expect(error.status).to eq(HttpStatus::FORBIDDEN)
        end
      end
    end
  end

  describe ".add_comment" do
    it "adds comment successfully" do
      ComplaintService.add_comment(complaint.id, admin_user, "Admin comment")
      result = ComplaintService.add_comment(complaint.id, regular_user, "Test comment")

      expect(result[:success]).to be true
      expect(result[:comment].comment).to eq("Test comment")
      expect(result[:comment].user_type).to eq(regular_user.user_type)
    end

    it "updates complaint status when admin adds first comment" do
      result = ComplaintService.add_comment(complaint.id, admin_user, "Admin response")

      expect(result[:success]).to be true
      expect(complaint.reload.status).to eq("in_progress")
    end

    it "does not update status when admin adds second comment" do
      create(:complaint_comment, complaint: complaint, user_type: "admin")

      ComplaintService.add_comment(complaint.id, admin_user, "Second admin comment")

      expect(complaint.reload.status).to eq("pending")
    end

    it "raises error when complaint not found" do
      expect {
        ComplaintService.add_comment(999, regular_user, "Test")
      }.to raise_error(HttpError) do |error|
        expect(error.message).to eq("Complaint not found.")
        expect(error.status).to eq(HttpStatus::NOT_FOUND)
      end
    end

    it "raises error when comment save fails" do
      allow_any_instance_of(ComplaintComment).to receive(:save).and_return(false)
      allow_any_instance_of(ComplaintComment).to receive(:errors).and_return(
        double(full_messages: [ "Comment is required" ])
      )

      expect {
        ComplaintService.add_comment(complaint.id, regular_user, "")
      }.to raise_error(HttpError) do |error|
        expect(error.message).to include("Failed to save comment")
        expect(error.status).to eq(HttpStatus::UNPROCESSABLE_ENTITY)
      end
    end
  end

  describe ".update_status" do
    context "with admin user" do
      it "updates complaint status successfully" do
        result = ComplaintService.update_status(complaint.id, "resolved", admin_user)

        expect(result[:success]).to be true
        expect(complaint.reload.status).to eq("resolved")
      end
    end

    context "with invalid status" do
      it "raises error for invalid status" do
        expect {
          ComplaintService.update_status(complaint.id, "invalid_status", admin_user)
        }.to raise_error(HttpError) do |error|
          expect(error.message).to include("Invalid or missing status")
          expect(error.status).to eq(HttpStatus::BAD_REQUEST)
        end
      end

      it "raises error for missing status" do
        expect {
          ComplaintService.update_status(complaint.id, nil, admin_user)
        }.to raise_error(HttpError) do |error|
          expect(error.message).to include("Invalid or missing status")
          expect(error.status).to eq(HttpStatus::BAD_REQUEST)
        end
      end
    end

    context "with non-admin user" do
      it "raises forbidden error" do
        expect {
          ComplaintService.update_status(complaint.id, "resolved", regular_user)
        }.to raise_error(HttpError) do |error|
          expect(error.message).to eq("Only admins can update complaint status.")
          expect(error.status).to eq(HttpStatus::FORBIDDEN)
        end
      end
    end

    context "with invalid complaint" do
      it "raises error when complaint not found" do
        expect {
          ComplaintService.update_status(999, "resolved", admin_user)
        }.to raise_error(HttpError) do |error|
          expect(error.message).to eq("Complaint not found.")
          expect(error.status).to eq(HttpStatus::NOT_FOUND)
        end
      end

      it "raises error when complaint_id is nil" do
        expect {
          ComplaintService.update_status(nil, "resolved", admin_user)
        }.to raise_error(HttpError) do |error|
          expect(error.message).to eq("Complaint Id is required.")
          expect(error.status).to eq(HttpStatus::NOT_FOUND)
        end
      end
    end

    it "raises error when update fails" do
      allow_any_instance_of(Complaint).to receive(:update).and_return(false)

      expect {
        ComplaintService.update_status(complaint.id, "resolved", admin_user)
      }.to raise_error(HttpError) do |error|
        expect(error.message).to eq("Failed to update complaint status.")
        expect(error.status).to eq(HttpStatus::UNPROCESSABLE_ENTITY)
      end
    end
  end

  describe ".delete_complaint" do
    context "by complaint owner" do
      it "deletes complaint successfully" do
        allow(CloudinaryService).to receive(:delete_image).and_return(true)

        result = ComplaintService.delete_complaint(complaint.id, regular_user)

        expect(result[:success]).to be true
        expect(result[:message]).to eq("Complaint deleted successfully")
        expect(Complaint.find_by(id: complaint.id)).to be_nil
      end
    end

    context "by admin" do
      it "deletes complaint successfully" do
        allow(CloudinaryService).to receive(:delete_image).and_return(true)

        result = ComplaintService.delete_complaint(complaint.id, admin_user)

        expect(result[:success]).to be true
        expect(Complaint.find_by(id: complaint.id)).to be_nil
      end
    end

    context "with attachment" do
      let(:complaint_with_attachment) do
        create(:complaint, user: regular_user, attachment: "http://example.com/image.jpg")
      end

      it "deletes attachment from cloudinary" do
        expect(CloudinaryService).to receive(:delete_image).with("http://example.com/image.jpg").and_return(true)

        ComplaintService.delete_complaint(complaint_with_attachment.id, regular_user)
      end

      it "raises error when attachment deletion fails" do
        allow(CloudinaryService).to receive(:delete_image).and_return(false)

        expect {
          ComplaintService.delete_complaint(complaint_with_attachment.id, regular_user)
        }.to raise_error(HttpError) do |error|
          expect(error.message).to eq("Failed to delete attachment on this complaint.")
          expect(error.status).to eq(HttpStatus::BAD_REQUEST)
        end
      end
    end

    context "unauthorized user" do
      let(:other_user) { create(:user) }

      it "raises forbidden error" do
        expect {
          ComplaintService.delete_complaint(complaint.id, other_user)
        }.to raise_error(HttpError) do |error|
          expect(error.message).to eq("You are not authorized to delete this complaint.")
          expect(error.status).to eq(HttpStatus::FORBIDDEN)
        end
      end
    end

    it "raises error when complaint not found" do
      expect {
        ComplaintService.delete_complaint(999, regular_user)
      }.to raise_error(HttpError) do |error|
        expect(error.message).to eq("Complaint not found")
        expect(error.status).to eq(HttpStatus::NOT_FOUND)
      end
    end
  end

  describe ".delete_comment" do
    let(:comment) { create(:complaint_comment, complaint: complaint) }

    context "by complaint owner" do
      it "deletes comment successfully" do
        result = ComplaintService.delete_comment(comment.id, regular_user)

        expect(result[:success]).to be true
        expect(result[:message]).to eq("Comment deleted successfully")
        expect(ComplaintComment.find_by(id: comment.id)).to be_nil
      end
    end

    context "by admin" do
      it "deletes comment successfully" do
        result = ComplaintService.delete_comment(comment.id, admin_user)

        expect(result[:success]).to be true
        expect(ComplaintComment.find_by(id: comment.id)).to be_nil
      end
    end

    context "unauthorized user" do
      let(:other_user) { create(:user) }

      it "raises forbidden error" do
        expect {
          ComplaintService.delete_comment(comment.id, other_user)
        }.to raise_error(HttpError) do |error|
          expect(error.message).to eq("You are not authorized to delete this comment")
          expect(error.status).to eq(HttpStatus::FORBIDDEN)
        end
      end
    end

    it "raises error when comment not found" do
      expect {
        ComplaintService.delete_comment(999, regular_user)
      }.to raise_error(HttpError) do |error|
        expect(error.message).to eq("Comment not found")
        expect(error.status).to eq(HttpStatus::NOT_FOUND)
      end
    end
  end
end
