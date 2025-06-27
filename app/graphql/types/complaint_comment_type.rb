module Types
  class ComplaintCommentType < Types::BaseObject
    field :id, ID, null: false
    field :complaint_id, ID, null: false
    field :user_type, String, null: false
    field :user_email, String, null: false
    field :comment, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :complaint, Types::ComplaintType, null: false
  end
end
