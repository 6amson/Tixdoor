module Types
  class DeletePayloadType < Types::BaseObject
    field :success, Boolean, null: false
    field :message, String, null: true
  end
end
