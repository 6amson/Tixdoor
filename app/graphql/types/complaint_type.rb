module Types
  class ComplaintType < Types::BaseObject
    field :id, ID, null: false
    field :complaint_type, String, null: false
    field :user_id, String, null: false
    field :complain, String, null: false
    field :attachment, String, null: true
    field :status, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :user, Types::UserType, null: false
    field :complaint_comments, [ Types::ComplaintCommentType ], null: true
  end
end
