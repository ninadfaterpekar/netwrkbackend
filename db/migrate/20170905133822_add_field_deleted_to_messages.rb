class AddFieldDeletedToMessages < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :deleted, :boolean, default: false
  end
end
