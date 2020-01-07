class AddUserPublicProfileToMessages < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :user_public_profile, :boolean
  end
end
