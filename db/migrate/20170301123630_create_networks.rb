class CreateNetworks < ActiveRecord::Migration[5.0]
  def change
    create_table :networks do |t|
      t.integer :post_code
      t.string :name
      t.integer :users_count

      t.timestamps
    end
  end
end
