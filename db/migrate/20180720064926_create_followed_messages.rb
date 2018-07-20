class CreateFollowedMessages < ActiveRecord::Migration[5.0]
  def change
    create_table :followed_messages do |t|
      t.integer :user_id
      t.integer :message_id
      t.datetime :created_at
      t.datetime :updated_at
      t.boolean :followed

      t.timestamps
    end
  end
end
