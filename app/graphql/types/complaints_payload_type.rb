module Types
  class ComplaintsPayloadType < Types::BaseObject
    field :success, Boolean, null: false
    field :complaints, [ Types::ComplaintType ], null: true
    field :pagination, Types::PaginationInfoType, null: true
  end
end
