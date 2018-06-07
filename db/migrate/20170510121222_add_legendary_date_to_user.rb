class AddLegendaryDateToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :legendary_at, :datetime
  end
end
