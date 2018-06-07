class AddAttachmentToImage < ActiveRecord::Migration[5.0]
  def up
    add_attachment :images, :image
  end

  def down
    remove_attachment :images, :image
  end
end
