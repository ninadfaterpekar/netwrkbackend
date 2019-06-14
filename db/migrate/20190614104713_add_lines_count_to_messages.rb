class AddLinesCountToMessages < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :lines_count, :integer
  end
end
