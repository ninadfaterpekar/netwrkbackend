class AddSomvoDetailsToMessages < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :start_date, :datetime
    add_column :messages, :weekly_status, :integer, comment: '-1 for Turned off, 1 for Turned On, 0 for Inactive for weekly, 2 for expired', default: 0
    add_column :messages, :notification_status, :integer, comment: '-1 for excluded, 0 for not sent, 1 for sent', default: 0
  end
end
