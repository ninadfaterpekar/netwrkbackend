class AddPasswordSaltToMessages < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :password_salt, :string
  end
end
