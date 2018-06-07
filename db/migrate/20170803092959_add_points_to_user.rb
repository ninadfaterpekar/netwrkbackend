class AddPointsToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :points_count, :integer, default: 0
  end
end
