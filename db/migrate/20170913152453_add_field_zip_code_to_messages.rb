class AddFieldZipCodeToMessages < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :post_code, :integer
  end
end
