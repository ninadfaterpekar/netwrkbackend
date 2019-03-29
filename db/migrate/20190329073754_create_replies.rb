class CreateReplies < ActiveRecord::Migration[5.0]
  def change
    create_table :replies do |t|
    	t.belongs_to :message, foreign_key: true
      	t.timestamps
    end
  end
end
