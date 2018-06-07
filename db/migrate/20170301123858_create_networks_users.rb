class CreateNetworksUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :networks_users do |t|
      t.integer :user_id
      t.integer :network_id

      t.timestamps
    end
  end
end
