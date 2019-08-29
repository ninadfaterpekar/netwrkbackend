class AddReadToRoomsUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :rooms_users, :read, :boolean
    add_column :rooms_users, :unread_count, :integer
  end
end
