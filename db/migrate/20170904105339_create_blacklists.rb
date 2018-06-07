class CreateBlacklists < ActiveRecord::Migration[5.0]
  def change
    create_table :blacklists do |t|
      t.belongs_to :user, index: true
      t.belongs_to :target, index: true
    end
  end
end
