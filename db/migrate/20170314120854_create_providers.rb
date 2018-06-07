class CreateProviders < ActiveRecord::Migration[5.0]
  def change
    create_table :providers do |t|
      t.integer :user_id
      t.string :token
      t.string :secret
      t.string :name

      t.timestamps
    end
  end
end
