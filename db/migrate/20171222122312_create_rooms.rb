class CreateRooms < ActiveRecord::Migration[5.0]
  def change
    create_table :rooms do |t|
      t.belongs_to :message, foreign_key: true
      t.timestamps
    end
  end
end
