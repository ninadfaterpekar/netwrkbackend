class AddColumnToMessages < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :social_id, :string
  end
end
