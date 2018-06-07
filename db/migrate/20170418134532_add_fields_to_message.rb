class AddFieldsToMessage < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :network_id, :integer
  end
end
