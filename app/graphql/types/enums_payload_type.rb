module Types
  class EnumsPayloadType < Types::BaseObject
    field :complaint_types, [ String ], null: false
    field :complaint_statuses, [ String ], null: false
    field :user_types, [ String ], null: false
  end
end
