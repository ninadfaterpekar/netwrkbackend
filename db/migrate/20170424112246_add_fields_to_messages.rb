class AddFieldsToMessages < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :public, :boolean, default: true
  end
end
