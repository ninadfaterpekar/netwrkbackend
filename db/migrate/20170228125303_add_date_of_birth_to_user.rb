class AddDateOfBirthToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :date_of_birthday, :date
  end
end
