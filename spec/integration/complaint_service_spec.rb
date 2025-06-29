require "rails_helper"

RSpec.describe ComplaintService, type: :integration do
  let(:regular_user) { create(:user, :regular) }
  let(:admin_user) { create(:user, :admin) }

  describe "Complete complaint workflow" do
    it "handles full complaint lifecycle" do
      # Create complaint
      complaint_params = {
        complaint_type: "payment_issue",
        user_id: regular_user.id,
        complain: "I was charged incorrectly",
        attachment: nil
      }

      allow(ComplaintNotificationService).to receive(:notify_admins_of)

      create_result = ComplaintService.create_complaint(complaint_params)
      expect(create_result[:success]).to be true

      complaint = create_result[:complaint]
      expect(complaint.status).to eq("pending")
      expect(ComplaintNotificationService).to have_received(:notify_admins_of).with(complaint)

      # Admin responds (first admin comment changes status)
      admin_comment_result = ComplaintService.add_comment(
        complaint.id,
        admin_user,
        "Thank you for reporting this. We are investigating."
      )
      expect(admin_comment_result[:success]).to be true
      expect(complaint.reload.status).to eq("in_progress") # Status changes

      # User adds can comment
      user_comment_result = ComplaintService.add_comment(
        complaint.id,
        regular_user,
        "Let me clarify - this happened on my last bill"
      )

      expect(user_comment_result[:success]).to be true
      #   expect(admin_comment_result[:success]).to be true
      expect(complaint.reload.status).to eq("in_progress") # Status changes

      # Step 4: Admin adds second comment (status remains same)
      ComplaintService.add_comment(
        complaint.id,
        admin_user,
        "Update: We found the issue and will process a refund."
      )
      expect(complaint.reload.status).to eq("in_progress") # Status unchanged

      # Step 5: Admin resolves complaint
      update_result = ComplaintService.update_status(complaint.id, "resolved", admin_user)
      expect(update_result[:success]).to be true
      expect(complaint.reload.status).to eq("resolved")

      # Step 6: Verify complete complaint data
      get_result = ComplaintService.get_complaint(complaint.id)
      expect(get_result[:success]).to be true
      expect(get_result[:complaint]["complaint_comments"].length).to eq(3)
      expect(get_result[:complaint]["status"]).to eq("resolved")
    end
  end

  describe "Complex filtering and pagination scenarios" do
    before do
      # Create test data
      @user1 = create(:user, :regular)
      @user2 = create(:user, :regular)

      # User1 complaints
      @complaint1 = create(:complaint, user: @user1, complaint_type: "payment_issue", status: "pending")
      @complaint2 = create(:complaint, user: @user1, complaint_type: "service_issue", status: "resolved")

      # User2 complaints
      @complaint3 = create(:complaint, user: @user2, complaint_type: "payment_issue", status: "in_progress")
      @complaint4 = create(:complaint, user: @user2, complaint_type: "technical_issue", status: "pending")

      # Add comments to some complaints
      create(:complaint_comment, complaint: @complaint1, user_type: "admin")
      create(:complaint_comment, complaint: @complaint3, user_type: "admin")
      create(:complaint_comment, complaint: @complaint1, user_type: "regular")
      create(:complaint_comment, complaint: @complaint3, user_type: "regular")
    end

    context "for regular users" do
      it "returns only user complaints with proper filtering" do
        # Test basic user filtering
        result = ComplaintService.get_all_complaints({}, user: @user1, page: 1, per_page: 10)
        expect(result[:complaints].length).to eq(2)
        expect(result[:complaints].map { |c| c["id"] }).to contain_exactly(@complaint1.id, @complaint2.id)

        # Test status filtering
        result = ComplaintService.get_all_complaints(
          { status: "pending" },
          user: @user1,
          page: 1,
          per_page: 10,
        )
        expect(result[:complaints].length).to eq(1)
        expect(result[:complaints].first["id"]).to eq(@complaint1.id)

        # Test complaint type filtering
        result = ComplaintService.get_all_complaints(
          { complaint_type: "payment_issue" },
          user: @user1,
          page: 1,
          per_page: 10,
        )
        expect(result[:complaints].length).to eq(1)
        expect(result[:complaints].first["id"]).to eq(@complaint1.id)
      end

      it "includes complaint comments in response" do
        result = ComplaintService.get_all_complaints({}, user: @user1, page: 1, per_page: 10)

        complaint_with_comments = result[:complaints].find { |c| c["id"] == @complaint1.id }
        expect(complaint_with_comments["complaint_comments"].length).to eq(2)

        complaint_without_comments = result[:complaints].find { |c| c["id"] == @complaint2.id }
        expect(complaint_without_comments["complaint_comments"].length).to eq(0)
      end
    end

    context "for admin users" do
      it "returns all complaints with proper filtering" do
        # Test admin sees all complaints
        result = ComplaintService.get_all_complaints({}, user: admin_user, page: 1, per_page: 10)
        expect(result[:complaints].length).to eq(4)

        # Test status filtering for admin
        result = ComplaintService.get_all_complaints(
          { status: "pending" },
          user: admin_user,
          page: 1,
          per_page: 10,
        )
        expect(result[:complaints].length).to eq(2)
        expect(result[:complaints].map { |c| c["id"] }).to contain_exactly(@complaint1.id, @complaint4.id)

        # Test complaint type filtering for admin
        result = ComplaintService.get_all_complaints(
          { complaint_type: "payment_issue" },
          user: admin_user,
          page: 1,
          per_page: 10,
        )
        expect(result[:complaints].length).to eq(2)
        expect(result[:complaints].map { |c| c["id"] }).to contain_exactly(@complaint1.id, @complaint3.id)
      end
    end

    it "handles pagination correctly" do
      result = ComplaintService.get_all_complaints({}, user: admin_user, page: 1, per_page: 2)

      expect(result[:complaints].length).to eq(2)
      expect(result[:pagination][:current_page]).to eq(1)
      expect(result[:pagination][:total_pages]).to eq(2)
      expect(result[:pagination][:total_count]).to eq(4)

      # Test second page
      result = ComplaintService.get_all_complaints({}, user: admin_user, page: 2, per_page: 2)
      expect(result[:complaints].length).to eq(2)
      expect(result[:pagination][:current_page]).to eq(2)
    end
  end

  describe "Error handling across service methods" do
    it "maintains data consistency when errors occur" do
      # Test attachment upload failure doesn't create complaint
      attachment = fixture_file_upload("test_image.png", "image/png")
      params = {
        complaint_type: "payment_issue",
        user_id: regular_user.id,
        complain: "Test complaint",
        attachment: attachment
      }

      allow(CloudinaryService).to receive(:upload_image).and_return(nil)

      expect {
        ComplaintService.create_complaint(params)
      }.to raise_error(HttpError)

      expect(Complaint.where(user_id: regular_user.id)).to be_empty
    end

    it "handles concurrent comment additions" do
      complaint = create(:complaint, user: regular_user)

      # Simulate concurrent admin comments
      threads = []
      2.times do |i|
        threads << Thread.new do
          ComplaintService.add_comment(complaint.id, admin_user, "Admin comment #{i}")
        end
      end

      threads.each(&:join)

      # Only one admin comment should change status
      expect(complaint.reload.status).to eq("in_progress")
      expect(complaint.complaint_comments.where(user_type: "admin").count).to eq(2)
    end
  end

  describe "Authorization across all methods" do
    let(:complaint) { create(:complaint, user: regular_user) }
    let(:other_user) { create(:user, :regular) }
    let(:comment) { create(:complaint_comment, complaint: complaint) }

    it "enforces authorization rules consistently" do
      # Regular user cannot update complaint status
      expect {
        ComplaintService.update_status(complaint.id, "resolved", regular_user)
      }.to raise_error(HttpError, /Only admins can update/)

      # User cannot delete other user's complaint
      expect {
        ComplaintService.delete_complaint(complaint.id, other_user)
      }.to raise_error(HttpError, /not authorized to delete/)

      # User cannot delete comment on other user's complaint
      expect {
        ComplaintService.delete_comment(comment.id, other_user)
      }.to raise_error(HttpError, /not authorized to delete/)

      # Admin can perform all operations
      expect {
        ComplaintService.update_status(complaint.id, "resolved", admin_user)
        ComplaintService.delete_comment(comment.id, admin_user)
        ComplaintService.delete_complaint(complaint.id, admin_user)
      }.not_to raise_error
    end
  end

  describe "Real-world edge cases" do
    it "handles complaint with multiple attachments and comments deletion" do
      # Create complaint with attachment
      complaint = create(:complaint, :with_attachment, user: regular_user)

      # Add multiple comments
      3.times do |i|
        create(:complaint_comment, complaint: complaint, comment: "Comment #{i}")
      end

      allow(CloudinaryService).to receive(:delete_image).and_return(true)

      result = ComplaintService.delete_complaint(complaint.id, regular_user)

      expect(result[:success]).to be true
      expect(CloudinaryService).to have_received(:delete_image)
      expect(ComplaintComment.where(complaint_id: complaint.id)).to be_empty
      expect(Complaint.find_by(id: complaint.id)).to be_nil
    end

    it "handles empty filter parameters gracefully" do
      complaint = create(:complaint, user: regular_user)

      # Test with empty hash
      result = ComplaintService.get_all_complaints({}, user: regular_user, page: 1, per_page: 10)
      expect(result[:success]).to be true

      # Test with nil values
      result = ComplaintService.get_all_complaints(
        { status: nil, complaint_type: "" },
        user: regular_user,
        page: 1,
        per_page: 10,
      )
      expect(result[:success]).to be true
      expect(result[:complaints].length).to eq(1)
    end
  end
end
