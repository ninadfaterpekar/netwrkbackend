class AddTypeToMessages < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :type, :string
  end
end
