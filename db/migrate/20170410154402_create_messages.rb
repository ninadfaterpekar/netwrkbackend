class CreateMessages < ActiveRecord::Migration[5.0]
  def change
    create_table :messages do |t|
      t.text :text
      t.integer :user_id
      t.decimal :lng
      t.decimal :lat
      t.boolean :undercover

      t.timestamps
    end
  end
end
