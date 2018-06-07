class AddFieldToLockedMessage < ActiveRecord::Migration[5.0]
  def change
    add_column :locked_messages, :unlocked, :boolean
  end
end
