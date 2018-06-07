class AddRoleFieldsToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :role_name, :string
    add_column :users, :role_description, :string
    add_column :users, :role_image_url, :string
  end
end
