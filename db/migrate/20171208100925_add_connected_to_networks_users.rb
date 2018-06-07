class AddConnectedToNetworksUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :networks_users, :connected, :boolean, default: true
    add_column :networks_users, :last_entrance_at, :date
  end
end
