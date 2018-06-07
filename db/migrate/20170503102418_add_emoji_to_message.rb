class AddEmojiToMessage < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :is_emoji, :boolean, default: false
  end
end
