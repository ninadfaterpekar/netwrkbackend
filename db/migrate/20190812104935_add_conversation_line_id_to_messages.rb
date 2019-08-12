class AddConversationLineIdToMessages < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :conversation_line_id, :integer
  end
end
