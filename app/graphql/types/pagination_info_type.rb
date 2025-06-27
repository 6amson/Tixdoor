module Types
  class PaginationInfoType < Types::BaseObject
    field :current_page, Integer, null: false
    field :total_pages, Integer, null: false
    field :total_count, Integer, null: false
  end
end
