class AddWelcomeEmailToApplicationSettings < ActiveRecord::Migration[5.0]
  def change
    add_column :application_settings, 'email_welcome', :string
  end
end
