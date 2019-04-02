class AddReplyCountToMessages < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :reply_count, :integer
  end
end
