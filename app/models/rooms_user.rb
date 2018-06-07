class RoomsUser < ApplicationRecord
  belongs_to :user
  belongs_to :room, counter_cache: :users_count
end
