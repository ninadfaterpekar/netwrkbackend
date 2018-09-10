class AddPlaceNameToMessages < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :place_name, :string
  end
end
