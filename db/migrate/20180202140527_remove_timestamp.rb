class RemoveTimestamp < ActiveRecord::Migration[5.0]
  def change
    remove_column :networks_users, :created_at, :datetime
    remove_column :networks_users, :updated_at, :datetime
  end
end
