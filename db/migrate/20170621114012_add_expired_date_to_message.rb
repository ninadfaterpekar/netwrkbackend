class AddExpiredDateToMessage < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :expire_date, :datetime
  end
end
