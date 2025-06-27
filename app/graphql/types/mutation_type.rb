module Types
  class MutationType < Types::BaseObject
    field :sign_in, mutation: Mutations::SignIn
    field :sign_up, mutation: Mutations::SignUp
    field :sign_out, mutation: Mutations::SignOut
    field :create_complaint, mutation: Mutations::CreateComplaint
    field :add_comment, mutation: Mutations::AddComment
    field :update_complaint_status, mutation: Mutations::UpdateComplaintStatus
    field :delete_complaint, mutation: Mutations::DeleteComplaint
    field :delete_comment, mutation: Mutations::DeleteComment
  end
end
