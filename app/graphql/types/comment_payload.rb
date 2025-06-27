module Types
  class CommentPayloadType < Types::BaseObject
    field :success, Boolean, null: false
    field :comment, Types::ComplaintCommentType, null: true
  end
end
