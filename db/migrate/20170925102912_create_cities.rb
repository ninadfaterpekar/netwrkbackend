class CreateCities < ActiveRecord::Migration[5.0]
  def change
    create_table :cities do |t|
      t.string :google_place_id
      t.string :name
    end
  end
end
