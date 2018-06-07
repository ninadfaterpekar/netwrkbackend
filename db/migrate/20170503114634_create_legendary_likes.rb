class CreateLegendaryLikes < ActiveRecord::Migration[5.0]
  def change
    create_table :legendary_likes do |t|
      t.integer :message_id
      t.integer :user_id

      t.timestamps
    end
  end
end
