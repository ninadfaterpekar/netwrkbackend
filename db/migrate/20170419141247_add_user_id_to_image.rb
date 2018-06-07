class AddUserIdToImage < ActiveRecord::Migration[5.0]
  def change
    add_column :images, :message_id, :integer
  end
end
