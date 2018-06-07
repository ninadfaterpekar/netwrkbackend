class AddAuthTokenToIuser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :auth_token, :string
    add_column :users, :phone, :string
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
  end
end
