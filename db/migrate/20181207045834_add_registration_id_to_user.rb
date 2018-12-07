class AddRegistrationIdToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :registration_id, :string
  end
end
