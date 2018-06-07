class AddHeroAvatarToUser < ActiveRecord::Migration[5.0]
  def up
    add_attachment :users, :hero_avatar
  end

  def down
    remove_attachment :users, :hero_avatar
  end
end
