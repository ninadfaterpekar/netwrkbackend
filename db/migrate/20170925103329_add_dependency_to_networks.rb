class AddDependencyToNetworks < ActiveRecord::Migration[5.0]
  def change
    add_column :networks, :city_id, :integer
    add_index :networks, :city_id 
  end
end
