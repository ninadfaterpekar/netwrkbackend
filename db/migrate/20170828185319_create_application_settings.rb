class CreateApplicationSettings < ActiveRecord::Migration[5.0]
  def change
    create_table :application_settings do |t|
      t.integer :singleton_guard, unique: true, index: true
      t.text :home_page
    end
  end
end
