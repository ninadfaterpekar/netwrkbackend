class ChangeUnlockedDefault < ActiveRecord::Migration[5.0]
  def change
    change_column :locked_messages, :unlocked, :boolean, default: false
  end
end
