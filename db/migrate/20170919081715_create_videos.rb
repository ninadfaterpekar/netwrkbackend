class CreateVideos < ActiveRecord::Migration[5.0]
  def change
    create_table :videos do |t|
      t.attachment :video
      t.string :url
      t.belongs_to :message
      t.timestamps
    end
  end
end
