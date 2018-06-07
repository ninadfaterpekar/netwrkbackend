class AddLegendaryToMessages < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :legendary, :boolean
  end
end
