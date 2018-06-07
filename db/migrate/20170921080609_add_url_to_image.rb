class AddUrlToImage < ActiveRecord::Migration[5.0]
  def change
    add_column :images, :url, :string
  end
end
