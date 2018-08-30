class AddRoleNameToMessages < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :role_name, :string
  end
end
