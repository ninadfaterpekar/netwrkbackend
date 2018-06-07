class CreateRoomsUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :rooms_users do |t|
      t.belongs_to :room
      t.belongs_to :user
    end
    add_column :rooms, :users_count, :integer
  end
end
