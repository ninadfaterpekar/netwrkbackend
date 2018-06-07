class AddLockedToMessages < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :locked, :boolean, default: false
    add_column :messages, :password_hash, :string
    add_column :messages, :hint, :string
  end
end
