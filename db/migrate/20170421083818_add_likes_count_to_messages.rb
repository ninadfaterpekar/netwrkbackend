class AddLikesCountToMessages < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :likes_count, :integer, default: 0
  end
end
