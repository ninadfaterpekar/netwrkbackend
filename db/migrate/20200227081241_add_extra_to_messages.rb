class AddExtraToMessages < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :extra, :text
  end
end
