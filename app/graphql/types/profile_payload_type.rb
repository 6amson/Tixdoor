module Types
  class ProfilePayloadType < Types::BaseObject
    field :success, Boolean, null: false
    field :user, Types::UserType, null: true
    field :complaints, [ Types::ComplaintType ], null: true
    field :pagination, Types::PaginationInfoType, null: true
  end
end
