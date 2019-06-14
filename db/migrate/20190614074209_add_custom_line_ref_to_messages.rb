class AddCustomLineRefToMessages < ActiveRecord::Migration[5.0]
  def change
  	add_column :messages, :custom_line_id, :integer
    add_index :messages, :custom_line_id
  end
end
