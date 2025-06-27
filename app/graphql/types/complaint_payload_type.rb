module Types
  class ComplaintPayloadType < Types::BaseObject
    field :success, Boolean, null: false
    field :complaint, Types::ComplaintType, null: true
  end
end
