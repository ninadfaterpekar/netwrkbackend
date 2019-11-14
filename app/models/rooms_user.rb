class RoomsUser < ApplicationRecord
  belongs_to :user
  belongs_to :room, counter_cache: :users_count

  def user
    u = User.find_by(id: user_id)
    u.as_json(methods: %i[id avatar_url hero_avatar_url], only: %i[name role_name])
  end
end
