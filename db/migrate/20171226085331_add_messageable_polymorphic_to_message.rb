class AddMessageablePolymorphicToMessage < ActiveRecord::Migration[5.0]
  def change
    change_table :messages do |t|
      t.references :messageable, polymorphic: true, index: true
    end
    remove_index :messages, name: :index_messages_on_network_id, column: :network_id
    remove_column :messages, :network_id, :integer
  end
end
