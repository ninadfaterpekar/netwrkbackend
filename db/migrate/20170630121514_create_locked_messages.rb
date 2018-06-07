class CreateLockedMessages < ActiveRecord::Migration[5.0]
  def change
    create_table :locked_messages do |t|
      t.integer :user_id
      t.integer :message_id

      t.timestamps
    end
  end
end
