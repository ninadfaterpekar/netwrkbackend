class AddDefaultToLegendaryCount < ActiveRecord::Migration[5.0]
  def up
    change_column :messages, :legendary_count, :integer, default: 0
  end

  def down
    change_column :messages, :legendary_count, :integer
  end
end
