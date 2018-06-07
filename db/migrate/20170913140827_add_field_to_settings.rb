class AddFieldToSettings < ActiveRecord::Migration[5.0]
  def change
    add_column :application_settings, :email_connect_to_network, :string
  end
end
