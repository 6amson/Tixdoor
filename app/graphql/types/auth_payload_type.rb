module Types
  class AuthPayloadType < Types::BaseObject
    field :success, Boolean, null: false
    field :user, Types::UserType, null: true
    field :token, String, null: true
    field :message, String, null: true
  end
end
