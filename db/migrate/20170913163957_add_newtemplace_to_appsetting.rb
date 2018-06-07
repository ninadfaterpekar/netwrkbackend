class AddNewtemplaceToAppsetting < ActiveRecord::Migration[5.0]
  def change
    add_column :application_settings, :email_legendary_mail, :string
  end
end
