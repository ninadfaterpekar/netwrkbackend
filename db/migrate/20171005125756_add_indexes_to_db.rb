class AddIndexesToDb < ActiveRecord::Migration[5.0]
  def change
    add_index :deleted_messages, :user_id
    add_index :deleted_messages, :message_id
    add_index :images, :message_id
    add_index :legendary_likes, :user_id
    add_index :legendary_likes, :message_id
    add_index :locked_messages, :user_id
    add_index :locked_messages, :message_id
    add_index :messages, :user_id
    add_index :messages, :network_id
    add_index :networks_users, :user_id
    add_index :networks_users, :network_id
    add_index :providers, :user_id
    add_index :user_likes, :user_id
    add_index :user_likes, :message_id
  end
end
