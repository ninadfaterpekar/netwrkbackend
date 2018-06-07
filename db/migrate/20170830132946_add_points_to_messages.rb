class AddPointsToMessages < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :points, :integer, default: 0
  end
end
