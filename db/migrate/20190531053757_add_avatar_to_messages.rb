class AddAvatarToMessages < ActiveRecord::Migration[5.0]
  def self.up
    add_attachment :messages, :avatar
  end

  def self.down
    remove_attachment :messages, :avatar
  end
end
