class AddPostPermalinkToMessage < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :post_permalink, :string
  end
end
