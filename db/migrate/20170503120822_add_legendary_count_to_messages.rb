class AddLegendaryCountToMessages < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :legendary_count, :integer, default: 0
  end
end
